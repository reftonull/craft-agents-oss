@testable import AgentsMobileCore
import ComposableArchitecture2
import ConcurrencyExtras
import Foundation
import Testing
import XCTest

@Suite("SessionsFeature")
struct SessionsFeatureTests {
  @Test
  func `opening sessions fetches remote items by recency`() async throws {
    try await withMainSerialExecutor {
      let older = RemoteSession(id: "older", lastMessageAt: 1, name: "Older")
      let newer = RemoteSession(id: "newer", lastMessageAt: 2, name: "Newer")
      let pairing = try Pairing(token: "token", url: #require(URL(string: "ws://desktop.local:9100")), workspaceID: "workspace-1")
      let store = await TestStoreActor(initialState: SessionsFeature.State(pairing: pairing)) {
        SessionsFeature()
          .dependency(\.rpcClient, .mock(sessions: [older, newer]))
      }

      await store.send(.task) {
        $0.list = .loading
      }
      await store.receive(\.sessionsResponse) {
        $0.list = .loaded(SessionsFeature.Loaded(sessions: [newer, older]))
      }
    }
  }

  @Test
  func `pull to refresh preserves current rows during request`() async throws {
    try await withMainSerialExecutor {
      let old = RemoteSession(id: "old", lastMessageAt: 1, name: "Old")
      let new = RemoteSession(id: "new", lastMessageAt: 2, name: "New")
      let pairing = try Pairing(token: "token", url: #require(URL(string: "ws://desktop.local:9100")), workspaceID: "workspace-1")
      let loaded = SessionsFeature.Loaded(sessions: [old])
      let store = await TestStoreActor(initialState: SessionsFeature.State(list: .loaded(loaded), pairing: pairing)) {
        SessionsFeature()
          .dependency(\.rpcClient, .mock(sessions: [new]))
      }

      await store.send(.refreshButtonTapped) {
        $0.list = .refreshing(loaded)
      }
      await store.receive(\.sessionsResponse) {
        $0.list = .loaded(SessionsFeature.Loaded(sessions: [new]))
      }
    }
  }

  @Test
  func `refresh error retains previous sessions`() async throws {
    try await withMainSerialExecutor {
      let old = RemoteSession(id: "old", lastMessageAt: 1, name: "Old")
      let pairing = try Pairing(token: "token", url: #require(URL(string: "ws://desktop.local:9100")), workspaceID: "workspace-1")
      let loaded = SessionsFeature.Loaded(sessions: [old])
      let store = await TestStoreActor(initialState: SessionsFeature.State(list: .loaded(loaded), pairing: pairing)) {
        SessionsFeature()
          .dependency(\.rpcClient, .mock(error: RPCClientError.disconnected))
      }

      await store.send(.refreshButtonTapped) {
        $0.list = .refreshing(loaded)
      }
      await store.receive(\.sessionsResponse) {
        $0.list = .refreshFailed(loaded, .connection("Disconnected"))
      }
    }
  }
}

/// This one reducer-only assertion intentionally uses XCTest instead of Swift Testing.
/// FlowDeck currently mis-parses this particular Swift Testing/TCA test shape as two
/// ghost child failures, even though the underlying XCTest runner reports it passing.
/// Keeping it as XCTest preserves coverage while avoiding noisy, misleading summaries.
final class SessionsFeatureXCTests: XCTestCase {
  func testUnavailableServerPresentsFailedSessionsScreen() async throws {
    let pairing = try Pairing(
      token: "token",
      url: XCTUnwrap(URL(string: "ws://desktop.local:9100")),
      workspaceID: "workspace-1"
    )
    let store = await StoreActor(initialState: SessionsFeature.State(list: .loading, pairing: pairing)) {
      SessionsFeature()
    }

    await store.send(.sessionsResponse(.failure(.connection("Disconnected"))))

    let list = await store.state.list
    XCTAssertEqual(list, .failed(.connection("Disconnected")))
  }
}

private extension RPCClient {
  static func mock(sessions: [RemoteSession]) -> RPCClient {
    RPCClient { request in
      await Task.yield()
      return MockRPCConnection(request: request, result: .success(sessions))
    }
  }

  static func mock(error: any Error) -> RPCClient {
    RPCClient { request in
      await Task.yield()
      return MockRPCConnection(request: request, result: .failure(error))
    }
  }
}

private actor MockRPCConnection: RPCConnection {
  let request: RPCConnectionRequest
  let result: Result<[RemoteSession], any Error>

  init(request: RPCConnectionRequest, result: Result<[RemoteSession], any Error>) {
    self.request = request
    self.result = result
  }

  func close() async {}

  func events() async -> AsyncThrowingStream<RPCConnectionEvent, any Error> {
    AsyncThrowingStream { continuation in
      continuation.finish()
    }
  }

  func invokeJSON(channel: String, args: [JSONValue]) async throws -> JSONValue {
    #expect(channel == RPCChannel.sessionsGet)
    return try JSONValue.encode(result.get())
  }
}
