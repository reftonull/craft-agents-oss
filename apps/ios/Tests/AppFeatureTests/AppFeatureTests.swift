@testable import AppFeature
import ComposableArchitecture2
@testable import ConnectionFeature
import Database
import DependenciesTestSupport
import Foundation
import Sharing
import Testing

@Suite(
  "AppFeature",
  .dependencies {
    $0.defaultAppStorage = .inMemory
    try $0.bootstrapDatabase()
  }
)
struct AppFeatureTests {
  @Test
  func `no saved workspaces starts in onboarding`() {
    @Shared(value: nil) var selectedWorkspaceID: Workspace.ID?

    let state = AppFeature.State(
      savedWorkspaces: [],
      selectedWorkspaceID: $selectedWorkspaceID
    )

    guard case .onboarding = state.route else {
      Issue.record("Expected no saved workspaces to start the app in onboarding")
      return
    }
    #expect(state.savedWorkspaces.isEmpty)
    #expect(selectedWorkspaceID == nil)
  }

  @Test
  func `saved workspace starts in tabs`() throws {
    let workspace = try testWorkspace()
    @Shared(value: workspace.id) var selectedWorkspaceID: Workspace.ID?

    let state = AppFeature.State(
      savedWorkspaces: [workspace],
      selectedWorkspaceID: $selectedWorkspaceID
    )

    guard case let .main(mainState) = state.route else {
      Issue.record("Expected saved workspace to start the app in tabs")
      return
    }
    #expect(mainState.workspace == workspace)
    #expect(mainState.sessions.workspace == workspace)
  }

  @Test
  func `connection response selects workspace through shared state`() async throws {
    let workspace = try testWorkspace()
    @Shared(value: nil) var selectedWorkspaceID: Workspace.ID?
    let store = await TestStoreActor(initialState: AppFeature.State(selectedWorkspaceID: $selectedWorkspaceID)) {
      AppFeature()
    }

    await store.send(.route(.onboarding(.connectionResponse(.success(workspace))))) {
      $0.selectedWorkspaceID = workspace.id
      $0.routeStorage = .onboarding(ConnectionFeature.State.DebugSnapshot(
        form: ConnectionFeature.Form(),
        phase: .idle,
        selectedWorkspaceID: workspace.id
      ))
    }
    #expect(selectedWorkspaceID == workspace.id)
  }
}

func testWorkspace(
  id rawID: String = "00000000-0000-0000-0000-000000000101",
  remoteWorkspaceID: String = "workspace-1",
  displayName: String = "Personal",
  serverURL: String = "ws://desktop.local:9100",
  tokenReference: String = "secret-token",
  openedAt: TimeInterval = 1000
) throws -> Workspace {
  try Workspace(
    id: #require(UUID(uuidString: rawID)),
    remoteWorkspaceID: remoteWorkspaceID,
    displayName: displayName,
    serverURL: serverURL,
    tokenReference: tokenReference,
    createdAt: Date(timeIntervalSince1970: openedAt - 20),
    updatedAt: Date(timeIntervalSince1970: openedAt - 10),
    lastOpenedAt: Date(timeIntervalSince1970: openedAt)
  )
}
