import ComposableArchitecture2
import ConnectionFeature
import Observation
import UIKit

final class AppViewController: UIViewController {
  private enum PresentedRoute: Equatable {
    case main
    case onboarding
  }

  private let store: StoreOf<AppFeature>
  private var presentedRoute: PresentedRoute?

  init(store: StoreOf<AppFeature>) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground
    observeStore()
  }

  private func observeStore() {
    withObservationTracking {
      render()
    } onChange: { [weak self] in
      Task { @MainActor in
        self?.observeStore()
      }
    }
  }

  private func render() {
    let routeStore = store.scope(state: \.route, action: \.route)

    switch AppRouteFeature.switch(store: routeStore) {
    case let .onboarding(onboardingStore):
      guard presentedRoute != .onboarding else { return }
      setRootViewController(
        UINavigationController(rootViewController: ConnectionViewController(store: onboardingStore)),
        route: .onboarding
      )

    case let .main(mainStore):
      guard presentedRoute != .main else { return }
      setRootViewController(
        TabViewController(store: mainStore),
        route: .main
      )
    }
  }

  private func setRootViewController(_ viewController: UIViewController, route: PresentedRoute) {
    for child in children {
      child.willMove(toParent: nil)
      child.view.removeFromSuperview()
      child.removeFromParent()
    }

    addChild(viewController)
    view.addSubview(viewController.view)
    viewController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
      viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    viewController.didMove(toParent: self)
    presentedRoute = route
  }
}
