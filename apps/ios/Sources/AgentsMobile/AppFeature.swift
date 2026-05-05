import ComposableArchitecture2
import Foundation
import Sharing

struct Pairing: Codable, Equatable {
  var token: String
  var url: URL
  var workspaceID: String
}

extension SharedKey where Self == AppStorageKey<Pairing?> {
  static var agentsMobilePairing: Self {
    .appStorage("agentsMobilePairing")
  }
}

@Feature
enum AppRouteFeature {
  case onboarding(ConnectionFeature)
  case main(TabFeature)
}

@Feature
struct AppFeature {
  struct State {
    @Shared(.agentsMobilePairing) var pairing: Pairing?
    var route: AppRouteFeature.State

    init(pairing: Shared<Pairing?> = Shared(.agentsMobilePairing)) {
      _pairing = pairing
      route = if let pairing = pairing.wrappedValue {
        .main(TabFeature.State(pairing: pairing))
      } else {
        .onboarding(ConnectionFeature.State())
      }
    }
  }

  enum Action {
    case route(AppRouteFeature.Action)
  }

  var body: some Feature {
    Scope(state: \.route, action: \.route) {
      AppRouteFeature.body
    }

    Update { state, action in
      switch action {
      case let .route(.onboarding(.delegate(.pairingCompleted(pairing)))):
        state.$pairing.withLock { $0 = pairing }
        state.route = .main(TabFeature.State(pairing: pairing))

      case .route(.main(.sessions(.delegate(.repairRequested)))):
        state.$pairing.withLock { $0 = nil }
        state.route = .onboarding(ConnectionFeature.State())

      case .route:
        break
      }
    }
  }
}

extension Pairing: Sendable {}
