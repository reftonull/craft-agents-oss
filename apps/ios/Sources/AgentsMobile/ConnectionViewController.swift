import ComposableArchitecture2
import Observation
import UIKit

final class ConnectionViewController: UIViewController {
  private let store: StoreOf<ConnectionFeature>

  private let statusLabel = UILabel()
  private let summariesLabel = UILabel()
  private let urlField = UITextField()
  private let tokenField = UITextField()
  private let workspaceField = UITextField()
  private let connectButton = UIButton(type: .system)
  private let disconnectButton = UIButton(type: .system)
  private let clearLogButton = UIButton(type: .system)
  private let eventTextView = UITextView()

  init(store: StoreOf<ConnectionFeature>) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
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

    summariesLabel.font = .preferredFont(forTextStyle: .footnote)
    summariesLabel.adjustsFontForContentSizeCategory = true
    summariesLabel.textColor = .secondaryLabel
    summariesLabel.numberOfLines = 0

    configureTextField(urlField, placeholder: "ws://192.168.1.10:9100")
    urlField.keyboardType = .URL
    urlField.textContentType = .URL
    urlField.autocapitalizationType = .none
    urlField.addTarget(self, action: #selector(urlFieldChanged), for: .editingChanged)

    configureTextField(tokenField, placeholder: "Mobile companion token")
    tokenField.isSecureTextEntry = true
    tokenField.textContentType = .password
    tokenField.autocapitalizationType = .none
    tokenField.addTarget(self, action: #selector(tokenFieldChanged), for: .editingChanged)

    configureTextField(workspaceField, placeholder: "Workspace ID (optional; first workspace if blank)")
    workspaceField.autocapitalizationType = .none
    workspaceField.addTarget(self, action: #selector(workspaceFieldChanged), for: .editingChanged)

    connectButton.setTitle("Connect", for: .normal)
    connectButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)

    disconnectButton.setTitle("Disconnect", for: .normal)
    disconnectButton.addTarget(self, action: #selector(disconnectButtonTapped), for: .touchUpInside)

    clearLogButton.setTitle("Clear Log", for: .normal)
    clearLogButton.addTarget(self, action: #selector(clearLogButtonTapped), for: .touchUpInside)

    eventTextView.isEditable = false
    eventTextView.alwaysBounceVertical = true
    eventTextView.backgroundColor = .secondarySystemBackground
    eventTextView.layer.cornerRadius = 12
    eventTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    eventTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)

    let buttonStack = UIStackView(arrangedSubviews: [connectButton, disconnectButton, clearLogButton])
    buttonStack.axis = .horizontal
    buttonStack.alignment = .center
    buttonStack.distribution = .fillEqually
    buttonStack.spacing = 12

    let formStack = UIStackView(arrangedSubviews: [
      labeled("Server URL", urlField),
      labeled("Token", tokenField),
      labeled("Workspace", workspaceField),
      buttonStack,
    ])
    formStack.axis = .vertical
    formStack.spacing = 12

    let stackView = UIStackView(arrangedSubviews: [
      statusLabel,
      summariesLabel,
      formStack,
      eventTextView,
    ])
    stackView.axis = .vertical
    stackView.spacing = 16
    stackView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
      stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
      stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
      eventTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 220),
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
    statusLabel.text = store.phaseDescription

    let summaries = [store.workspacesSummary, store.sessionsSummary]
      .filter { !$0.isEmpty }
      .joined(separator: " • ")
    summariesLabel.text = summaries.isEmpty ? "Enter the server URL/token from desktop Settings → Mobile Companion." : summaries

    if urlField.text != store.urlString, !urlField.isFirstResponder {
      urlField.text = store.urlString
    }
    if tokenField.text != store.token, !tokenField.isFirstResponder {
      tokenField.text = store.token
    }
    if workspaceField.text != store.workspaceID, !workspaceField.isFirstResponder {
      workspaceField.text = store.workspaceID
    }

    connectButton.isEnabled = !store.isConnecting
    disconnectButton.isEnabled = store.isConnecting || store.isConnected

    eventTextView.text = store.eventLog
      .map { entry in
        let prefix = switch entry.kind {
        case .error: "❌"
        case .event: "📨"
        case .status: "•"
        }
        return "\(prefix) \(entry.message)"
      }
      .joined(separator: "\n")

    if !eventTextView.text.isEmpty {
      let bottom = NSRange(location: eventTextView.text.count - 1, length: 1)
      eventTextView.scrollRangeToVisible(bottom)
    }
  }

  @objc private func clearLogButtonTapped() {
    store.send(.clearLogButtonTapped)
  }

  @objc private func connectButtonTapped() {
    view.endEditing(true)
    store.send(.connectButtonTapped)
  }

  @objc private func disconnectButtonTapped() {
    store.send(.disconnectButtonTapped)
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
