import ComposableArchitecture2
import Foundation

@Feature
struct TabFeature {
  struct State {
    var pairing: Pairing
    var sessions: SessionsFeature.State

    init(pairing: Pairing) {
      self.pairing = pairing
      sessions = SessionsFeature.State(pairing: pairing)
    }
  }

  enum Action {
    case sessions(SessionsFeature.Action)
  }

  var body: some Feature {
    Scope(state: \.sessions, action: \.sessions) {
      SessionsFeature()
    }
  }
}
