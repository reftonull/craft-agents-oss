import ComposableArchitecture2
import ConnectionFeature
import Database
import Foundation
import RPCClient

@Feature
struct SessionsFeature {
  struct State {
    var list: ListState = .notLoaded
    var workspace: Workspace

    init(
      list: ListState = .notLoaded,
      workspace: Workspace
    ) {
      self.list = list
      self.workspace = workspace
    }
  }

  enum ListState: Equatable {
    case notLoaded
    case loading
    case loaded(Loaded)
    case refreshing(Loaded)
    case failed(Failure)
    case refreshFailed(Loaded, Failure)

    var loaded: Loaded? {
      switch self {
      case let .loaded(loaded), let .refreshing(loaded), let .refreshFailed(loaded, _):
        loaded
      case .failed, .loading, .notLoaded:
        nil
      }
    }

    var sessions: [RemoteSession] {
      loaded?.sessions ?? []
    }

    var isLoading: Bool {
      switch self {
      case .loading, .refreshing:
        true
      case .failed, .loaded, .notLoaded, .refreshFailed:
        false
      }
    }
  }

  struct Loaded: Equatable {
    var sessions: [RemoteSession]
  }

  enum Failure: Error, Equatable {
    case connection(String)

    var message: String {
      switch self {
      case let .connection(message):
        message
      }
    }
  }

  enum Action {
    case refreshButtonTapped
    case sessionsResponse(Result<[RemoteSession], Failure>)
    case task
  }

  @Dependency(\.rpcClient) var rpcClient
  @StoreTaskID var loadTaskID

  var body: some Feature {
    Update { state, action in
      switch action {
      case .refreshButtonTapped:
        switch state.list {
        case let .loaded(loaded), let .refreshFailed(loaded, _):
          state.list = .refreshing(loaded)
          loadSessions(workspace: state.workspace)
        case .failed, .notLoaded:
          state.list = .loading
          loadSessions(workspace: state.workspace)
        case .loading, .refreshing:
          break
        }

      case let .sessionsResponse(.failure(failure)):
        switch state.list {
        case let .refreshing(loaded):
          state.list = .refreshFailed(loaded, failure)
        case .failed, .loaded, .loading, .notLoaded, .refreshFailed:
          state.list = .failed(failure)
        }

      case let .sessionsResponse(.success(sessions)):
        state.list = .loaded(Loaded(sessions: sessions.sortedByRecency()))

      case .task:
        switch state.list {
        case .failed, .notLoaded:
          state.list = .loading
          loadSessions(workspace: state.workspace)
        case .loaded, .loading, .refreshing, .refreshFailed:
          break
        }
      }
    }
  }

  private func loadSessions(workspace: Workspace) {
    store.addTask(id: loadTaskID) {
      guard let serverURL = workspace.serverWebSocketURL else {
        try store.send(.sessionsResponse(.failure(.connection("Workspace has an invalid server URL."))))
        return
      }

      var connection: (any RPCConnection)?
      let response: Result<[RemoteSession], Failure>
      do {
        let workspaceConnection = try await rpcClient.connect(RPCConnectionRequest(
          url: serverURL,
          token: workspace.tokenReference,
          workspaceID: workspace.remoteWorkspaceID
        ))
        connection = workspaceConnection
        let sessions = try await workspaceConnection.invoke(
          [RemoteSession].self,
          channel: RPCChannel.sessionsGet
        )
        await workspaceConnection.close()
        connection = nil
        response = .success(sessions)
      } catch is CancellationError {
        if let connection { await connection.close() }
        return
      } catch {
        if let connection { await connection.close() }
        response = .failure(.connection(ConnectionFeature.describe(error)))
      }
      try store.send(.sessionsResponse(response))
    }
  }
}

extension [RemoteSession] {
  func sortedByRecency() -> [RemoteSession] {
    sorted { lhs, rhs in
      (lhs.lastMessageAt ?? lhs.createdAt ?? 0) > (rhs.lastMessageAt ?? rhs.createdAt ?? 0)
    }
  }
}
