import ComposableArchitecture2
import Foundation

@Feature
struct ConnectionFeature {
  struct State {
    var eventLog: [EventLogEntry] = []
    var isConnected = false
    var isConnecting = false
    var nextLogID = 0
    var phaseDescription = "Disconnected"
    var sessionsSummary = ""
    var token = ""
    var urlString = "ws://127.0.0.1:9100"
    var workspaceID = ""
    var workspacesSummary = ""
  }

  enum Action {
    case clearLogButtonTapped
    case connectButtonTapped
    case connectionEvent(RPCConnectionEvent)
    case connectionFailed(String)
    case disconnectButtonTapped
    case disconnected
    case sessionsLoaded(Int)
    case tokenChanged(String)
    case urlChanged(String)
    case workspaceIDChanged(String)
    case workspacesLoaded([RemoteWorkspace], selectedWorkspaceID: String?)
  }

  @Dependency(\.rpcClient) var rpcClient
  @StoreTaskID var connectionTaskID

  var body: some Feature {
    Update { state, action in
      switch action {
      case .clearLogButtonTapped:
        state.eventLog.removeAll()

      case .connectButtonTapped:
        guard !state.isConnecting else { break }

        let urlString = state.urlString
        let token = state.token.trimmingCharacters(in: .whitespacesAndNewlines)
        let requestedWorkspaceID = state.workspaceID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !token.isEmpty else {
          appendLog(&state, kind: .error, message: "Token is required")
          break
        }

        let url: URL
        do {
          url = try Self.normalizedWebSocketURL(urlString)
        } catch {
          appendLog(&state, kind: .error, message: "Invalid URL: \(error.localizedDescription)")
          break
        }

        state.isConnected = false
        state.isConnecting = true
        state.phaseDescription = "Connecting to server…"
        state.sessionsSummary = ""
        state.workspacesSummary = ""
        appendLog(&state, kind: .status, message: "Connecting to \(url.absoluteString)")

        store.addTask(id: connectionTaskID) {
          var serverConnection: (any RPCConnection)?
          var workspaceConnection: (any RPCConnection)?

          do {
            let server = try await rpcClient.connect(
              RPCConnectionRequest(url: url, token: token)
            )
            serverConnection = server

            var serverIterator = await (server.events()).makeAsyncIterator()
            while let event = try await serverIterator.next() {
              try store.send(.connectionEvent(event))
              if case .connected = event { break }
            }

            let workspaces = try await server.invoke(
              [RemoteWorkspace].self,
              channel: RPCChannel.serverGetWorkspaces
            )
            let selectedWorkspaceID = requestedWorkspaceID.isEmpty
              ? workspaces.first?.id
              : requestedWorkspaceID
            try store.send(.workspacesLoaded(workspaces, selectedWorkspaceID: selectedWorkspaceID))

            await server.close()
            serverConnection = nil

            guard let selectedWorkspaceID, !selectedWorkspaceID.isEmpty else { return }

            let workspace = try await rpcClient.connect(
              RPCConnectionRequest(url: url, token: token, workspaceID: selectedWorkspaceID)
            )
            workspaceConnection = workspace
            var workspaceIterator = await (workspace.events()).makeAsyncIterator()
            var didLoadSessions = false

            while let event = try await workspaceIterator.next() {
              try store.send(.connectionEvent(event))

              if case .connected = event, !didLoadSessions {
                didLoadSessions = true
                let sessions = try await workspace.invoke(
                  [RemoteSession].self,
                  channel: RPCChannel.sessionsGet
                )
                try store.send(.sessionsLoaded(sessions.count))
              }
            }
          } catch is CancellationError {
            if let workspaceConnection { await workspaceConnection.close() }
            if let serverConnection { await serverConnection.close() }
          } catch {
            if let workspaceConnection { await workspaceConnection.close() }
            if let serverConnection { await serverConnection.close() }
            _ = try? store.send(.connectionFailed(Self.describe(error)))
          }
        }

      case let .connectionEvent(event):
        switch event {
        case .connecting:
          state.isConnecting = true
          state.phaseDescription = "Connecting…"
          appendLog(&state, kind: .status, message: "WebSocket connecting")

        case let .connected(info):
          state.isConnected = true
          state.isConnecting = false
          state.phaseDescription = "Connected: \(info.clientID)"
          appendLog(
            &state,
            kind: .status,
            message: "Handshake acknowledged. Channels: \(info.registeredChannels.count)"
          )

        case let .disconnected(info):
          state.isConnected = false
          state.isConnecting = false
          state.phaseDescription = "Disconnected"
          appendLog(&state, kind: .status, message: "Disconnected\(info.reason.map { ": \($0)" } ?? "")")

        case let .event(channel, args, seq):
          appendLog(
            &state,
            kind: .event,
            message: "\(channel)\(seq.map { " #\($0)" } ?? ""): \(Self.describe(args))"
          )

        case .handshaking:
          state.phaseDescription = "Handshaking…"
          appendLog(&state, kind: .status, message: "Sending Craft RPC handshake")
        }

      case let .connectionFailed(message):
        state.isConnected = false
        state.isConnecting = false
        state.phaseDescription = "Failed"
        appendLog(&state, kind: .error, message: message)

      case .disconnectButtonTapped:
        state.phaseDescription = "Disconnecting…"
        appendLog(&state, kind: .status, message: "Disconnect requested")
        store.addTask {
          connectionTaskID.cancel()
          _ = try? store.send(.disconnected)
        }

      case .disconnected:
        state.isConnected = false
        state.isConnecting = false
        state.phaseDescription = "Disconnected"

      case let .sessionsLoaded(count):
        state.sessionsSummary = "\(count) session\(count == 1 ? "" : "s") loaded"
        appendLog(&state, kind: .status, message: state.sessionsSummary)

      case let .tokenChanged(token):
        state.token = token

      case let .urlChanged(urlString):
        state.urlString = urlString

      case let .workspaceIDChanged(workspaceID):
        state.workspaceID = workspaceID

      case let .workspacesLoaded(workspaces, selectedWorkspaceID):
        state.workspacesSummary = "\(workspaces.count) workspace\(workspaces.count == 1 ? "" : "s") found"
        if let selectedWorkspaceID {
          state.workspaceID = selectedWorkspaceID
          appendLog(&state, kind: .status, message: "Selected workspace: \(selectedWorkspaceID)")
        }
        appendLog(&state, kind: .status, message: state.workspacesSummary)
      }
    }
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
        return "Connection timed out"
      case .disconnected:
        return "Disconnected"
      case .encodingFailed:
        return "Failed to encode RPC message"
      case let .invalidServerResponse(message):
        return "Invalid server response: \(message)"
      case .notConnected:
        return "Not connected"
      case let .protocolMismatch(server, client):
        return "Protocol mismatch. Server: \(server ?? "unknown"), client: \(client)"
      case let .requestTimedOut(channel):
        return "Request timed out: \(channel)"
      case let .serverError(error):
        return "Server error [\(error.code)]: \(error.message)"
      case .unimplemented:
        return "RPC client is not implemented"
      }
    }
    return error.localizedDescription
  }

  nonisolated static func describe(_ values: [JSONValue]) -> String {
    guard
      let data = try? JSONEncoder.craftRPC.encode(values),
      let string = String(data: data, encoding: .utf8)
    else { return "<unprintable>" }
    return string
  }

  private func appendLog(_ state: inout State, kind: EventLogEntry.Kind, message: String) {
    state.eventLog.append(
      EventLogEntry(
        id: state.nextLogID,
        kind: kind,
        message: message
      )
    )
    state.nextLogID += 1

    if state.eventLog.count > 200 {
      state.eventLog.removeFirst(state.eventLog.count - 200)
    }
  }
}

struct EventLogEntry: Codable, Equatable, Hashable, Identifiable {
  enum Kind: String, Codable, Equatable, Hashable {
    case error
    case event
    case status
  }

  var id: Int
  var kind: Kind
  var message: String
}

struct RemoteWorkspace: Decodable, Equatable, Hashable, Identifiable {
  var id: String
  var name: String
  var slug: String
}

struct RemoteSession: Decodable, Equatable, Hashable, Identifiable {
  var id: String
  var name: String?
}
