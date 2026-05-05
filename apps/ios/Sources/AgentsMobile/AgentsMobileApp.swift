import ComposableArchitecture2
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    configuration.delegateClass = SceneDelegate.self
    return configuration
  }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let store = Store(initialState: AppFeature.State()) {
      AppFeature()
    }

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = AppViewController(store: store)
    self.window = window
    window.makeKeyAndVisible()
  }
}

final class RootViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Agents Mobile"
    view.backgroundColor = .systemBackground

    let imageView = UIImageView(image: UIImage(systemName: "sparkles"))
    imageView.tintColor = .tintColor
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false

    let titleLabel = UILabel()
    titleLabel.text = "Agents Mobile"
    titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.textAlignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    let subtitleLabel = UILabel()
    subtitleLabel.text = "Native companion for Craft Agents"
    subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
    subtitleLabel.adjustsFontForContentSizeCategory = true
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.textAlignment = .center
    subtitleLabel.numberOfLines = 0
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

    let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel, subtitleLabel])
    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.spacing = 12
    stackView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stackView)

    NSLayoutConstraint.activate([
      imageView.widthAnchor.constraint(equalToConstant: 56),
      imageView.heightAnchor.constraint(equalToConstant: 56),

      stackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
      stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
      stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
    ])
  }
}
