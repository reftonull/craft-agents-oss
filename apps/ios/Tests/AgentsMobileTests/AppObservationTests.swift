@testable import AgentsMobileCore
import ComposableArchitecture2
import Foundation
import Observation
import Sharing
import Testing

@Suite("AppFeature observation")
struct AppObservationTests {
  @MainActor
  @Test
  func `route observation invalidates when switching from onboarding to main`() async throws {
    let pairing = try Pairing(
      token: "secret-token",
      url: #require(URL(string: "ws://desktop.local:9100")),
      workspaceID: "workspace-1"
    )
    @Shared(value: nil) var persistedPairing: Pairing?
    let store = Store(initialState: AppFeature.State(pairing: $persistedPairing)) {
      AppFeature()
    }
    let recorder = ObservationRecorder()

    withObservationTracking {
      _ = store.route.onboarding != nil
      _ = store.route.main != nil
    } onChange: {
      Task { @MainActor in
        recorder.recordInvalidation()
      }
    }

    await store.send(.route(.onboarding(.delegate(.pairingCompleted(pairing)))))?.value
    await Task.yield()

    #expect(recorder.invalidationCount == 1)
  }
}

@MainActor
private final class ObservationRecorder {
  var invalidationCount = 0

  func recordInvalidation() {
    invalidationCount += 1
  }
}
