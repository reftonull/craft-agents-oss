import ComposableArchitecture2
import ConnectionFeature
import Database
import Foundation
import Sharing
import SQLiteData

@Feature
enum AppRouteFeature {
  case onboarding(ConnectionFeature)
  case main(TabFeature)
}

@Feature
struct AppFeature {
  struct State {
    @FetchAll(Workspace.all) var savedWorkspaces: [Workspace]
    @Shared(.agentsMobileSelectedWorkspaceID) var selectedWorkspaceID: Workspace.ID?
    var routeStorage: AppRouteFeature.State

    var route: AppRouteFeature.State {
      get {
        if selectedWorkspaceID == nil,
           case let .onboarding(onboarding) = routeStorage
        {
          return .onboarding(onboarding)
        }

        if let currentWorkspace = Self.resolveCurrentWorkspace(
          in: savedWorkspaces,
          selectedWorkspaceID: selectedWorkspaceID
        ) {
          if case let .main(main) = routeStorage,
             main.workspace.id == currentWorkspace.id
          {
            return .main(main)
          }
          return .main(TabFeature.State(workspace: currentWorkspace))
        }

        if let selectedWorkspaceID,
           case let .main(main) = routeStorage,
           main.workspace.id == selectedWorkspaceID
        {
          return .main(main)
        }

        if case let .onboarding(onboarding) = routeStorage {
          return .onboarding(onboarding)
        }
        return .onboarding(ConnectionFeature.State(selectedWorkspaceID: $selectedWorkspaceID))
      }
      set { routeStorage = newValue }
    }

    init(
      savedWorkspaces: [Workspace] = [],
      selectedWorkspaceID: Shared<Workspace.ID?> = Shared(.agentsMobileSelectedWorkspaceID)
    ) {
      _savedWorkspaces = FetchAll(wrappedValue: savedWorkspaces, Workspace.all)
      _selectedWorkspaceID = selectedWorkspaceID
      routeStorage = Self.resolveCurrentWorkspace(
        in: savedWorkspaces,
        selectedWorkspaceID: selectedWorkspaceID.wrappedValue
      )
      .map { .main(TabFeature.State(workspace: $0)) }
      ?? .onboarding(ConnectionFeature.State(selectedWorkspaceID: selectedWorkspaceID))
    }

    static func resolveCurrentWorkspace(
      in workspaces: [Workspace],
      selectedWorkspaceID: Workspace.ID?
    ) -> Workspace? {
      let sortedWorkspaces = workspaces.sortedByFallbackPriority()
      if let selectedWorkspaceID,
         let selectedWorkspace = sortedWorkspaces.first(where: { $0.id == selectedWorkspaceID })
      {
        return selectedWorkspace
      }
      return sortedWorkspaces.first
    }
  }

  enum Action {
    case route(AppRouteFeature.Action)
  }

  var body: some Feature {
    Scope(state: \.route, action: \.route) {
      AppRouteFeature.body
    }

    Update { _, action in
      switch action {
      case .route:
        break
      }
    }
  }
}
