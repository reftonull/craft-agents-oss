import ComposableArchitecture2
import Observation
import UIKit

final class SessionsViewController: UIViewController {
  private let store: StoreOf<SessionsFeature>

  private let statusLabel = UILabel()
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)

  init(store: StoreOf<SessionsFeature>) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Sessions"
    view.backgroundColor = .systemBackground
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .refresh,
      target: self,
      action: #selector(refreshButtonTapped)
    )

    configureViews()
    observeStore()
    store.send(.task)
  }

  private func configureViews() {
    statusLabel.font = .preferredFont(forTextStyle: .subheadline)
    statusLabel.adjustsFontForContentSizeCategory = true
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    statusLabel.translatesAutoresizingMaskIntoConstraints = false

    tableView.dataSource = self
    tableView.delegate = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.refreshControl = UIRefreshControl()
    tableView.refreshControl?.addTarget(self, action: #selector(refreshButtonTapped), for: .valueChanged)

    view.addSubview(statusLabel)
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      statusLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      statusLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),

      tableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
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
    let count = store.list.sessions.count
    statusLabel.text = statusText(sessionCount: count)
    navigationItem.rightBarButtonItem?.isEnabled = !store.list.isLoading
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: pairingActionTitle,
      style: .plain,
      target: self,
      action: #selector(pairingActionButtonTapped)
    )

    if store.list.isLoading, !tableView.refreshControl!.isRefreshing, !store.list.sessions.isEmpty {
      tableView.refreshControl?.beginRefreshing()
    } else if !store.list.isLoading {
      tableView.refreshControl?.endRefreshing()
    }

    tableView.reloadData()
  }

  private func statusText(sessionCount: Int) -> String {
    switch store.list {
    case .notLoaded:
      "Ready to load sessions from workspace \(store.pairing.workspaceID)."
    case .loading:
      "Loading sessions from workspace \(store.pairing.workspaceID)…"
    case .loaded:
      "Connected to workspace \(store.pairing.workspaceID). \(sessionCount) session\(sessionCount == 1 ? "" : "s") available."
    case .refreshing:
      "Refreshing \(sessionCount) session\(sessionCount == 1 ? "" : "s")…"
    case let .failed(failure):
      "Couldn’t load sessions: \(failure.message)"
    case let .refreshFailed(_, failure):
      "Showing cached sessions. Refresh failed: \(failure.message)"
    }
  }

  @objc private func refreshButtonTapped() {
    store.send(.refreshButtonTapped)
  }

  private var pairingActionTitle: String {
    switch store.list {
    case .failed:
      "Re-pair"
    case .loaded, .loading, .notLoaded, .refreshFailed, .refreshing:
      "Logout"
    }
  }

  @objc private func pairingActionButtonTapped() {
    store.send(.repairButtonTapped)
  }
}

extension SessionsViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch store.list {
    case .failed, .loading, .notLoaded:
      1
    case .loaded, .refreshFailed, .refreshing:
      max(store.list.sessions.count, 1)
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch store.list {
    case .notLoaded, .loading:
      return loadingCell()

    case let .failed(failure):
      return errorCell(message: failure.message, pairingActionTitle: pairingActionTitle)

    case let .refreshFailed(loaded, failure):
      if loaded.sessions.isEmpty {
        return errorCell(message: failure.message, pairingActionTitle: pairingActionTitle)
      }
      return sessionCell(for: loaded.sessions[indexPath.row])

    case let .loaded(loaded), let .refreshing(loaded):
      guard !loaded.sessions.isEmpty else { return emptyCell() }
      return sessionCell(for: loaded.sessions[indexPath.row])
    }
  }

  private func loadingCell() -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = "Loading sessions…"
    cell.detailTextLabel?.text = "Checking the desktop workspace."
    cell.imageView?.image = UIImage(systemName: "arrow.clockwise")
    cell.imageView?.tintColor = .secondaryLabel
    return cell
  }

  private func emptyCell() -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = "No sessions yet"
    cell.detailTextLabel?.text = "Sessions from the desktop app will appear here."
    cell.imageView?.image = UIImage(systemName: "tray")
    cell.imageView?.tintColor = .secondaryLabel
    return cell
  }

  private func errorCell(message: String, pairingActionTitle: String) -> UITableViewCell {
    var content = UIListContentConfiguration.subtitleCell()
    content.image = UIImage(systemName: "exclamationmark.triangle")
    content.imageProperties.tintColor = .systemOrange
    content.text = "Couldn’t load sessions"
    content.secondaryText = "\(message)\nTap to retry, or use \(pairingActionTitle) to pair again."
    content.secondaryTextProperties.numberOfLines = 0

    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    cell.contentConfiguration = content
    cell.selectionStyle = .default
    return cell
  }

  private func sessionCell(for session: RemoteSession) -> UITableViewCell {
    var content = UIListContentConfiguration.subtitleCell()
    content.text = session.displayTitle
    content.textProperties.font = session.hasUnread == true
      ? .preferredFont(forTextStyle: .headline)
      : .preferredFont(forTextStyle: .body)
    content.secondaryText = session.subtitle
    content.secondaryTextProperties.numberOfLines = 2
    content.image = session.icon
    content.imageProperties.tintColor = session.iconTintColor

    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    cell.contentConfiguration = content
    cell.selectionStyle = .none
    cell.accessoryView = accessoryView(for: session)
    return cell
  }

  private func accessoryView(for session: RemoteSession) -> UIView? {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.spacing = 6

    if session.hasUnread == true {
      let dot = UIImageView(image: UIImage(systemName: "circle.fill"))
      dot.tintColor = .tintColor
      dot.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 8, weight: .bold)
      stackView.addArrangedSubview(dot)
    }

    if session.isProcessing == true || session.isAsyncOperationOngoing == true {
      let spinner = UIActivityIndicatorView(style: .medium)
      spinner.startAnimating()
      stackView.addArrangedSubview(spinner)
    }

    if session.isFlagged == true {
      let flag = UIImageView(image: UIImage(systemName: "flag.fill"))
      flag.tintColor = .systemOrange
      flag.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
      stackView.addArrangedSubview(flag)
    }

    if let relativeTime = session.relativeTime {
      let label = UILabel()
      label.text = relativeTime
      label.font = .preferredFont(forTextStyle: .caption2)
      label.textColor = .tertiaryLabel
      stackView.addArrangedSubview(label)
    }

    return stackView.arrangedSubviews.isEmpty ? nil : stackView
  }
}

extension SessionsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if case .failed = store.list {
      store.send(.refreshButtonTapped)
    }
  }

  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    if case .failed = store.list {
      return "If this keeps failing, re-pair from the desktop Mobile Companion settings."
    }
    if case .refreshFailed = store.list {
      return "Refresh failed. Pull to retry."
    }
    return nil
  }

  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard case .failed = store.list else { return nil }
    let repair = UIContextualAction(style: .destructive, title: "Re-pair") { [weak self] _, _, completion in
      self?.store.send(.repairButtonTapped)
      completion(true)
    }
    return UISwipeActionsConfiguration(actions: [repair])
  }
}

private extension RemoteSession {
  var displayTitle: String {
    if let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return name }
    if let preview = sanitizedPreview, !preview.isEmpty { return preview.truncated(to: 50) }
    return "New chat"
  }

  var subtitle: String? {
    var parts: [String] = []
    if let currentStatus = currentStatus?.message, !currentStatus.isEmpty {
      parts.append(currentStatus)
    } else if let preview = sanitizedPreview, preview != displayTitle {
      parts.append(preview.truncated(to: 88))
    }
    if let status = sessionStatus, !status.isEmpty { parts.append(status) }
    if let model, !model.isEmpty { parts.append(model) }
    if let messageCount { parts.append("\(messageCount) message\(messageCount == 1 ? "" : "s")") }
    if isArchived == true { parts.append("Archived") }
    if hidden == true { parts.append("Hidden") }
    return parts.isEmpty ? id : parts.joined(separator: " • ")
  }

  var icon: UIImage? {
    switch sessionStatus {
    case "in-progress":
      UIImage(systemName: "play.circle")
    case "needs-review":
      UIImage(systemName: "exclamationmark.circle")
    case "done":
      UIImage(systemName: "checkmark.circle")
    case "cancelled":
      UIImage(systemName: "xmark.circle")
    default:
      UIImage(systemName: "circle")
    }
  }

  var iconTintColor: UIColor {
    switch sessionStatus {
    case "in-progress": .systemBlue
    case "needs-review": .systemOrange
    case "done": .systemGreen
    case "cancelled": .systemRed
    default: .secondaryLabel
    }
  }

  var relativeTime: String? {
    guard let timestamp = lastMessageAt ?? createdAt else { return nil }
    let date = Date(timeIntervalSince1970: timestamp / 1000)
    let seconds = max(0, Int(Date().timeIntervalSince(date)))
    if seconds < 60 { return "\(max(1, seconds))s" }
    let minutes = seconds / 60
    if minutes < 60 { return "\(minutes)m" }
    let hours = minutes / 60
    if hours < 24 { return "\(hours)h" }
    let days = hours / 24
    if days < 7 { return "\(days)d" }
    let weeks = days / 7
    if weeks < 5 { return "\(weeks)w" }
    let months = days / 30
    if months < 12 { return "\(months)mo" }
    return "\(days / 365)y"
  }

  var sanitizedPreview: String? {
    preview?
      .replacingOccurrences(of: #"<edit_request>[\s\S]*?</edit_request>"#, with: "", options: .regularExpression)
      .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
      .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

private extension String {
  func truncated(to maxLength: Int) -> String {
    guard count > maxLength else { return self }
    let index = index(startIndex, offsetBy: maxLength)
    return String(self[..<index]).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
  }
}
