import ComposableArchitecture2
import Database
import Foundation

@Feature
struct TabFeature {
  struct State {
    var sessions: SessionsFeature.State
    var workspace: Workspace

    init(workspace: Workspace) {
      self.workspace = workspace
      sessions = SessionsFeature.State(workspace: workspace)
    }
  }

  enum Action {
    case logoutButtonTapped
    case sessions(SessionsFeature.Action)
  }

  var body: some Feature {
    Scope(state: \.sessions, action: \.sessions) {
      SessionsFeature()
    }

    Update { _, action in
      switch action {
      case .logoutButtonTapped:
        break

      case .sessions:
        break
      }
    }
  }
}
