@testable import AppFeature
import ComposableArchitecture2
import ConnectionFeature
import Database
import DependenciesTestSupport
import Foundation
import Observation
import Sharing
import Testing

@Suite(
  "AppFeature observation",
  .dependencies {
    $0.defaultAppStorage = .inMemory
    try $0.bootstrapDatabase()
  }
)
struct AppObservationTests {
  @MainActor
  @Test
  func `route observation invalidates when connection updates selected workspace`() async throws {
    let workspace = try testWorkspace(
      id: "00000000-0000-0000-0000-000000000201"
    )
    @Shared(value: nil) var selectedWorkspaceID: Workspace.ID?
    let store = Store(initialState: AppFeature.State(selectedWorkspaceID: $selectedWorkspaceID)) {
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

    await store.send(.route(.onboarding(.connectionResponse(.success(workspace)))))?.value
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
