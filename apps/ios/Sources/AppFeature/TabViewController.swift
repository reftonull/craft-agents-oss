import ComposableArchitecture2
import UIKit

final class TabViewController: UITabBarController {
  private let store: StoreOf<TabFeature>

  init(store: StoreOf<TabFeature>) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    configureTabs()
  }

  private func configureTabs() {
    let sessionsStore = store.scope(state: \.sessions, action: \.sessions)
    let sessionsViewController = SessionsViewController(store: sessionsStore)
    sessionsViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: "Logout",
      style: .plain,
      target: self,
      action: #selector(logoutButtonTapped)
    )

    let sessions = UINavigationController(rootViewController: sessionsViewController)
    sessions.tabBarItem = UITabBarItem(
      title: "Sessions",
      image: UIImage(systemName: "tray.full"),
      selectedImage: UIImage(systemName: "tray.full.fill")
    )

    viewControllers = [sessions]
    selectedIndex = 0
  }

  @objc private func logoutButtonTapped() {
    store.send(.logoutButtonTapped)
  }
}
