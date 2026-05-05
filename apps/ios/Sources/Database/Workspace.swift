import Foundation
import SQLiteData

@Table
public struct Workspace: Codable, Equatable, Identifiable, Sendable {
  public let id: UUID
  public var remoteWorkspaceID: String
  public var displayName: String
  public var serverURL: String
  public var tokenReference: String
  public var remoteSlug: String?
  public var createdAt: Date
  public var updatedAt: Date
  public var lastOpenedAt: Date?

  public init(
    id: UUID,
    remoteWorkspaceID: String,
    displayName: String,
    serverURL: URL,
    tokenReference: String,
    remoteSlug: String? = nil,
    createdAt: Date,
    updatedAt: Date,
    lastOpenedAt: Date? = nil
  ) {
    self.id = id
    self.remoteWorkspaceID = remoteWorkspaceID.trimmingCharacters(in: .whitespacesAndNewlines)
    self.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    self.serverURL = Workspace.normalizedServerURLString(serverURL)
    self.tokenReference = tokenReference
    self.remoteSlug = remoteSlug?.trimmingCharacters(in: .whitespacesAndNewlines)
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.lastOpenedAt = lastOpenedAt
  }

  public init(
    id: UUID,
    remoteWorkspaceID: String,
    displayName: String,
    serverURL: String,
    tokenReference: String,
    remoteSlug: String? = nil,
    createdAt: Date,
    updatedAt: Date,
    lastOpenedAt: Date? = nil
  ) throws {
    guard let url = URL(string: serverURL) else { throw WorkspaceError.invalidServerURL(serverURL) }
    self.init(
      id: id,
      remoteWorkspaceID: remoteWorkspaceID,
      displayName: displayName,
      serverURL: url,
      tokenReference: tokenReference,
      remoteSlug: remoteSlug,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastOpenedAt: lastOpenedAt
    )
  }

  public var serverWebSocketURL: URL? {
    URL(string: serverURL)
  }

  public static func normalizedServerURLString(_ url: URL) -> String {
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return url.absoluteString
    }

    components.scheme = components.scheme?.lowercased()
    components.host = components.host?.lowercased()
    components.fragment = nil

    while components.percentEncodedPath.count > 1,
          components.percentEncodedPath.hasSuffix("/")
    {
      components.percentEncodedPath.removeLast()
    }

    if components.percentEncodedPath == "/" {
      components.percentEncodedPath = ""
    }

    return components.url?.absoluteString ?? url.absoluteString
  }
}

public extension [Workspace] {
  func sortedByFallbackPriority() -> Self {
    sorted { lhs, rhs in
      let lhsDate = lhs.lastOpenedAt ?? lhs.updatedAt
      let rhsDate = rhs.lastOpenedAt ?? rhs.updatedAt
      if lhsDate != rhsDate { return lhsDate > rhsDate }
      if lhs.displayName != rhs.displayName { return lhs.displayName < rhs.displayName }
      return lhs.id.uuidString < rhs.id.uuidString
    }
  }
}

public enum WorkspaceError: Error, Equatable, Sendable {
  case emptyDisplayName
  case emptyRemoteWorkspaceID
  case invalidServerURL(String)
}

public enum WorkspaceSelection: Equatable, Sendable {
  case none
  case current(Workspace)
  case unavailable(savedWorkspaceID: UUID)
}
