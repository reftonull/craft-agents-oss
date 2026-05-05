@testable import AppFeature
import ClientModels
import ComposableArchitecture2
import ConnectionFeature
import Foundation
import Sharing
import Testing

@Suite("AppFeature")
struct AppFeatureTests {
  @Test
  func `persisted pairing starts in tabs`() throws {
    let pairing = try Pairing(
      token: "secret-token",
      url: #require(URL(string: "ws://desktop.local:9100")),
      workspaceID: "workspace-1"
    )
    @Shared(value: Optional(pairing)) var persistedPairing: Pairing?

    let state = AppFeature.State(pairing: $persistedPairing)

    guard case let .main(mainState) = state.route else {
      Issue.record("Expected persisted pairing to start the app in tabs")
      return
    }
    #expect(mainState.pairing == pairing)
    #expect(mainState.sessions.pairing == pairing)
  }

  @Test
  func `pairing delegate persists pairing and switches from onboarding to tabs`() async throws {
    let pairing = try Pairing(
      token: "secret-token",
      url: #require(URL(string: "ws://desktop.local:9100")),
      workspaceID: "workspace-1"
    )
    @Shared(value: nil) var persistedPairing: Pairing?
    let store = await TestStoreActor(initialState: AppFeature.State(pairing: $persistedPairing)) {
      AppFeature()
    }

    await store.send(.route(.onboarding(.delegate(.pairingCompleted(pairing))))) {
      $0.pairing = pairing
      $0.route = .main(
        TabFeature.State.DebugSnapshot(
          pairing: pairing,
          sessions: SessionsFeature.State.DebugSnapshot(
            list: .notLoaded,
            pairing: pairing
          )
        )
      )
    }
    #expect(persistedPairing == pairing)
  }
}
