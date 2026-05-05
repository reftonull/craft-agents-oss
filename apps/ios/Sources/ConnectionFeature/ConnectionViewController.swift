import ComposableArchitecture2
import Observation
import UIKit

public final class ConnectionViewController: UIViewController {
  private let store: StoreOf<ConnectionFeature>

  private let statusLabel = UILabel()
  private let detailLabel = UILabel()
  private let urlField = UITextField()
  private let tokenField = UITextField()
  private let workspaceField = UITextField()
  private let connectButton = UIButton(type: .system)

  public init(store: StoreOf<ConnectionFeature>) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    title = "Agents Mobile"
    view.backgroundColor = .systemBackground

    configureViews()
    observeStore()
  }

  private func configureViews() {
    statusLabel.font = .preferredFont(forTextStyle: .headline)
    statusLabel.adjustsFontForContentSizeCategory = true
    statusLabel.numberOfLines = 0

    detailLabel.font = .preferredFont(forTextStyle: .footnote)
    detailLabel.adjustsFontForContentSizeCategory = true
    detailLabel.textColor = .secondaryLabel
    detailLabel.numberOfLines = 0

    configureTextField(urlField, placeholder: "ws://192.168.1.10:9100")
    urlField.keyboardType = .URL
    urlField.textContentType = .URL
    urlField.autocapitalizationType = .none
    urlField.addTarget(self, action: #selector(urlFieldChanged), for: .editingChanged)

    configureTextField(tokenField, placeholder: "Mobile companion token")
    tokenField.isSecureTextEntry = true
    tokenField.textContentType = .oneTimeCode
    tokenField.autocapitalizationType = .none
    tokenField.addTarget(self, action: #selector(tokenFieldChanged), for: .editingChanged)

    configureTextField(workspaceField, placeholder: "Workspace ID (optional; first workspace if blank)")
    workspaceField.autocapitalizationType = .none
    workspaceField.addTarget(self, action: #selector(workspaceFieldChanged), for: .editingChanged)

    connectButton.setTitle("Connect", for: .normal)
    connectButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)

    let formStack = UIStackView(arrangedSubviews: [
      labeled("Server URL", urlField),
      labeled("Token", tokenField),
      labeled("Workspace", workspaceField),
      connectButton,
    ])
    formStack.axis = .vertical
    formStack.spacing = 12

    let stackView = UIStackView(arrangedSubviews: [
      statusLabel,
      detailLabel,
      formStack,
    ])
    stackView.axis = .vertical
    stackView.spacing = 16
    stackView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
      stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
    ])
  }

  private func configureTextField(_ textField: UITextField, placeholder: String) {
    textField.borderStyle = .roundedRect
    textField.placeholder = placeholder
    textField.clearButtonMode = .whileEditing
    textField.autocorrectionType = .no
    textField.spellCheckingType = .no
  }

  private func labeled(_ title: String, _ view: UIView) -> UIView {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .caption1)
    label.adjustsFontForContentSizeCategory = true
    label.textColor = .secondaryLabel

    let stackView = UIStackView(arrangedSubviews: [label, view])
    stackView.axis = .vertical
    stackView.spacing = 4
    return stackView
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
    statusLabel.text = store.phase.title
    detailLabel.text = store.phase.detail
    detailLabel.textColor = if case .failed = store.phase { .systemRed } else { .secondaryLabel }

    if urlField.text != store.form.urlString, !urlField.isFirstResponder {
      urlField.text = store.form.urlString
    }
    if tokenField.text != store.form.token, !tokenField.isFirstResponder {
      tokenField.text = store.form.token
    }
    if workspaceField.text != store.form.workspaceID, !workspaceField.isFirstResponder {
      workspaceField.text = store.form.workspaceID
    }

    connectButton.isEnabled = store.canConnect
    connectButton.setTitle(store.phase.isConnecting ? "Connecting…" : "Connect", for: .normal)
  }

  @objc private func connectButtonTapped() {
    view.endEditing(true)
    store.send(.connectButtonTapped)
  }

  @objc private func tokenFieldChanged() {
    store.send(.tokenChanged(tokenField.text ?? ""))
  }

  @objc private func urlFieldChanged() {
    store.send(.urlChanged(urlField.text ?? ""))
  }

  @objc private func workspaceFieldChanged() {
    store.send(.workspaceIDChanged(workspaceField.text ?? ""))
  }
}
