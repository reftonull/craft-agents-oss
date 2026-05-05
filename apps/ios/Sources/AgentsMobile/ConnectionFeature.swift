import ComposableArchitecture2
import Foundation

@Feature
struct ConnectionFeature {
  struct State {
    var form = Form()
    var phase: Phase = .idle

    var canConnect: Bool {
      !form.token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !phase.isConnecting
    }
  }

  struct Form: Equatable {
    var token = ""
    var urlString = "ws://127.0.0.1:9100"
    var workspaceID = ""
  }

  enum Phase: Equatable {
    case idle
    case connecting(Step)
    case failed(Failure)

    var isConnecting: Bool {
      if case .connecting = self { true } else { false }
    }
  }

  enum Step: Equatable {
    case openingServerSocket
    case handshakingServer
    case loadingWorkspaces
    case selectingWorkspace(workspaceCount: Int)
    case openingWorkspaceSocket(workspaceID: String)
    case handshakingWorkspace(workspaceID: String)
    case verifyingSessions(workspaceID: String)
  }

  enum Failure: Error, Equatable {
    case missingToken
    case invalidURL(String)
    case noWorkspaces
    case connection(String)
  }

  struct ValidatedRequest: Equatable {
    var requestedWorkspaceID: String?
    var token: String
    var url: URL
  }

  enum Action {
    case connectButtonTapped
    case delegate(Delegate)
    case pairingResponse(Result<Pairing, Failure>)
    case phaseChanged(Phase)
    case tokenChanged(String)
    case urlChanged(String)
    case workspaceIDChanged(String)

    enum Delegate: Equatable {
      case pairingCompleted(Pairing)
    }
  }

  @Dependency(\.rpcClient) var rpcClient
  @StoreTaskID var connectionTaskID

  var body: some Feature {
    Update { state, action in
      switch action {
      case .connectButtonTapped:
        guard !state.phase.isConnecting else { break }

        switch Self.validatedRequest(from: state.form) {
        case let .failure(failure):
          state.phase = .failed(failure)

        case let .success(request):
          state.phase = .connecting(.openingServerSocket)

          store.addTask(id: connectionTaskID) {
            var serverConnection: (any RPCConnection)?
            var workspaceConnection: (any RPCConnection)?

            do {
              let server = try await rpcClient.connect(
                RPCConnectionRequest(url: request.url, token: request.token)
              )
              serverConnection = server

              var serverIterator = await server.events().makeAsyncIterator()
              while let event = try await serverIterator.next() {
                if case .handshaking = event {
                  try store.send(.phaseChanged(.connecting(.handshakingServer)))
                }
                if case .connected = event { break }
              }

              try store.send(.phaseChanged(.connecting(.loadingWorkspaces)))
              let workspaces = try await server.invoke(
                [RemoteWorkspace].self,
                channel: RPCChannel.serverGetWorkspaces
              )
              try store.send(.phaseChanged(.connecting(.selectingWorkspace(workspaceCount: workspaces.count))))

              let selectedWorkspaceID = request.requestedWorkspaceID ?? workspaces.first?.id
              guard let selectedWorkspaceID, !selectedWorkspaceID.isEmpty else {
                throw Failure.noWorkspaces
              }

              await server.close()
              serverConnection = nil

              try store.send(.phaseChanged(.connecting(.openingWorkspaceSocket(workspaceID: selectedWorkspaceID))))
              let workspace = try await rpcClient.connect(
                RPCConnectionRequest(
                  url: request.url,
                  token: request.token,
                  workspaceID: selectedWorkspaceID
                )
              )
              workspaceConnection = workspace

              var workspaceIterator = await workspace.events().makeAsyncIterator()
              while let event = try await workspaceIterator.next() {
                if case .handshaking = event {
                  try store.send(.phaseChanged(.connecting(.handshakingWorkspace(workspaceID: selectedWorkspaceID))))
                }
                if case .connected = event { break }
              }

              try store.send(.phaseChanged(.connecting(.verifyingSessions(workspaceID: selectedWorkspaceID))))
              _ = try await workspace.invoke(
                [RemoteSession].self,
                channel: RPCChannel.sessionsGet
              )

              await workspace.close()
              workspaceConnection = nil

              try store.send(.pairingResponse(.success(Pairing(
                token: request.token,
                url: request.url,
                workspaceID: selectedWorkspaceID
              ))))
            } catch is CancellationError {
              if let workspaceConnection { await workspaceConnection.close() }
              if let serverConnection { await serverConnection.close() }
            } catch let failure as Failure {
              if let workspaceConnection { await workspaceConnection.close() }
              if let serverConnection { await serverConnection.close() }
              _ = try? store.send(.pairingResponse(.failure(failure)))
            } catch {
              if let workspaceConnection { await workspaceConnection.close() }
              if let serverConnection { await serverConnection.close() }
              _ = try? store.send(.pairingResponse(.failure(.connection(Self.describe(error)))))
            }
          }
        }

      case .delegate:
        break

      case let .pairingResponse(.failure(failure)):
        state.phase = .failed(failure)

      case let .pairingResponse(.success(pairing)):
        state.phase = .idle
        store.addTask {
          _ = try? store.send(.delegate(.pairingCompleted(pairing)))
        }

      case let .phaseChanged(phase):
        state.phase = phase

      case let .tokenChanged(token):
        state.form.token = token
        if case .failed(.missingToken) = state.phase, !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          state.phase = .idle
        }

      case let .urlChanged(urlString):
        state.form.urlString = urlString
        if case .failed(.invalidURL) = state.phase {
          state.phase = .idle
        }

      case let .workspaceIDChanged(workspaceID):
        state.form.workspaceID = workspaceID
      }
    }
  }

  nonisolated static func validatedRequest(from form: Form) -> Result<ValidatedRequest, Failure> {
    let token = form.token.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !token.isEmpty else { return .failure(.missingToken) }

    let url: URL
    do {
      url = try normalizedWebSocketURL(form.urlString)
    } catch {
      return .failure(.invalidURL(error.localizedDescription))
    }

    let workspaceID = form.workspaceID.trimmingCharacters(in: .whitespacesAndNewlines)
    return .success(ValidatedRequest(
      requestedWorkspaceID: workspaceID.isEmpty ? nil : workspaceID,
      token: token,
      url: url
    ))
  }

  nonisolated static func normalizedWebSocketURL(_ rawValue: String) throws -> URL {
    let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { throw URLError(.badURL) }

    let candidate: String = if trimmed.contains("://") {
      trimmed
    } else {
      "ws://\(trimmed)"
    }

    guard var components = URLComponents(string: candidate) else {
      throw URLError(.badURL)
    }

    switch components.scheme?.lowercased() {
    case "ws", "wss":
      break
    case "http":
      components.scheme = "ws"
    case "https":
      components.scheme = "wss"
    default:
      throw URLError(.unsupportedURL)
    }

    guard let host = components.host, !host.isEmpty, host != "0.0.0.0" else {
      throw URLError(.cannotFindHost)
    }

    guard let url = components.url else { throw URLError(.badURL) }
    return url
  }

  nonisolated static func describe(_ error: any Error) -> String {
    if let rpcError = error as? RPCClientError {
      switch rpcError {
      case let .channelUnavailable(channel):
        return "Server does not advertise channel: \(channel)"
      case .connectTimedOut:
        return "Timed out waiting for WebSocket connection"
      case .disconnected:
        return "Disconnected"
      case .encodingFailed:
        return "Failed to encode RPC message"
      case let .invalidServerResponse(message):
        return message
      case .notConnected:
        return "Not connected"
      case let .protocolMismatch(server, client):
        return "Protocol mismatch. Server: \(server ?? "unknown"), client: \(client)"
      case let .requestTimedOut(channel):
        return "Timed out waiting for response from \(channel)"
      case let .serverError(error):
        return error.message
      case .unimplemented:
        return "RPC client is not implemented"
      }
    }

    return error.localizedDescription
  }
}

extension ConnectionFeature.Phase {
  var title: String {
    switch self {
    case .idle:
      "Disconnected"
    case .connecting(.openingServerSocket):
      "Connecting to server…"
    case .connecting(.handshakingServer):
      "Handshaking with server…"
    case .connecting(.loadingWorkspaces):
      "Loading workspaces…"
    case let .connecting(.selectingWorkspace(workspaceCount)):
      "Found \(workspaceCount) workspace\(workspaceCount == 1 ? "" : "s")…"
    case let .connecting(.openingWorkspaceSocket(workspaceID)):
      "Connecting to workspace \(workspaceID)…"
    case .connecting(.handshakingWorkspace):
      "Opening workspace…"
    case .connecting(.verifyingSessions):
      "Verifying sessions…"
    case .failed:
      "Connection failed"
    }
  }

  var detail: String {
    switch self {
    case .idle:
      "Enter the server URL/token from desktop Settings → Mobile Companion."
    case .connecting:
      "Checking the desktop server and selected workspace."
    case let .failed(failure):
      failure.message
    }
  }
}

extension ConnectionFeature.Failure {
  var message: String {
    switch self {
    case .missingToken:
      "Token is required."
    case let .invalidURL(message):
      "Invalid server URL: \(message)"
    case .noWorkspaces:
      "No workspace was available. Enter a workspace ID or open a workspace in the desktop app."
    case let .connection(message):
      message
    }
  }
}

struct RemoteWorkspace: Decodable, Equatable, Hashable, Identifiable {
  var id: String
  var name: String
  var slug: String
}

struct RemoteSession: Codable, Equatable, Hashable, Identifiable {
  var createdAt: Double?
  var currentStatus: RemoteSessionStatus?
  var hasUnread: Bool?
  var hidden: Bool?
  var id: String
  var isArchived: Bool?
  var isAsyncOperationOngoing: Bool?
  var isFlagged: Bool?
  var isProcessing: Bool?
  var labels: [String]?
  var lastFinalMessageId: String?
  var lastMessageAt: Double?
  var lastMessageRole: String?
  var messageCount: Int?
  var model: String?
  var name: String?
  var preview: String?
  var sessionStatus: String?
  var workspaceId: String?
  var workspaceName: String?

  init(
    id: String,
    createdAt: Double? = nil,
    currentStatus: RemoteSessionStatus? = nil,
    hasUnread: Bool? = nil,
    hidden: Bool? = nil,
    isArchived: Bool? = nil,
    isAsyncOperationOngoing: Bool? = nil,
    isFlagged: Bool? = nil,
    isProcessing: Bool? = nil,
    labels: [String]? = nil,
    lastFinalMessageId: String? = nil,
    lastMessageAt: Double? = nil,
    lastMessageRole: String? = nil,
    messageCount: Int? = nil,
    model: String? = nil,
    name: String? = nil,
    preview: String? = nil,
    sessionStatus: String? = nil,
    workspaceId: String? = nil,
    workspaceName: String? = nil
  ) {
    self.createdAt = createdAt
    self.currentStatus = currentStatus
    self.hasUnread = hasUnread
    self.hidden = hidden
    self.id = id
    self.isArchived = isArchived
    self.isAsyncOperationOngoing = isAsyncOperationOngoing
    self.isFlagged = isFlagged
    self.isProcessing = isProcessing
    self.labels = labels
    self.lastFinalMessageId = lastFinalMessageId
    self.lastMessageAt = lastMessageAt
    self.lastMessageRole = lastMessageRole
    self.messageCount = messageCount
    self.model = model
    self.name = name
    self.preview = preview
    self.sessionStatus = sessionStatus
    self.workspaceId = workspaceId
    self.workspaceName = workspaceName
  }
}

struct RemoteSessionStatus: Codable, Equatable, Hashable {
  var message: String
  var statusType: String?
}

extension ConnectionFeature.Form: Sendable {}
extension ConnectionFeature.Phase: Sendable {}
extension ConnectionFeature.Step: Sendable {}
extension ConnectionFeature.Failure: Sendable {}
extension ConnectionFeature.ValidatedRequest: Sendable {}
