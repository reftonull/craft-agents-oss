@testable import AgentsMobileCore
import ComposableArchitecture2
import Foundation
import Testing

@Suite("ConnectionFeature")
struct ConnectionFeatureTests {
  @Test
  func `normalizes host and HTTP URLs to WebSocket URLs`() throws {
    #expect(try ConnectionFeature.normalizedWebSocketURL("192.168.1.10:9100").absoluteString == "ws://192.168.1.10:9100")
    #expect(try ConnectionFeature.normalizedWebSocketURL("http://desktop.local:9100").absoluteString == "ws://desktop.local:9100")
    #expect(try ConnectionFeature.normalizedWebSocketURL("https://desktop.local:9100").absoluteString == "wss://desktop.local:9100")
  }

  @Test
  func `rejects bind-all address as a client target`() {
    #expect(throws: URLError.self) {
      try ConnectionFeature.normalizedWebSocketURL("ws://0.0.0.0:9100")
    }
  }

  @Test
  func `validated request trims token and optional workspace`() throws {
    let result = ConnectionFeature.validatedRequest(from: ConnectionFeature.Form(
      token: " token ",
      urlString: "desktop.local:9100",
      workspaceID: " workspace-1 "
    ))

    let request = try result.get()
    #expect(request.token == "token")
    #expect(request.url.absoluteString == "ws://desktop.local:9100")
    #expect(request.requestedWorkspaceID == "workspace-1")
  }

  @Test
  func `connect with missing token fails without entering connecting state`() async {
    let store = await TestStoreActor(initialState: ConnectionFeature.State()) {
      ConnectionFeature()
    }

    await store.send(.connectButtonTapped) {
      $0.phase = .failed(.missingToken)
    }
  }

  @Test
  func `editing token clears missing token failure`() async {
    let store = await TestStoreActor(initialState: ConnectionFeature.State()) {
      ConnectionFeature()
    }

    await store.send(.connectButtonTapped) {
      $0.phase = .failed(.missingToken)
    }
    await store.send(.tokenChanged("secret")) {
      $0.form.token = "secret"
      $0.phase = .idle
    }
  }
}
