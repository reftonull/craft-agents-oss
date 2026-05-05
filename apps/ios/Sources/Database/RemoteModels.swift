import Foundation

public struct RemoteWorkspace: Decodable, Equatable, Hashable, Identifiable, Sendable {
  public var id: String
  public var name: String
  public var slug: String

  public init(id: String, name: String, slug: String) {
    self.id = id
    self.name = name
    self.slug = slug
  }
}

public struct RemoteSession: Codable, Equatable, Hashable, Identifiable, Sendable {
  public var createdAt: Double?
  public var currentStatus: RemoteSessionStatus?
  public var hasUnread: Bool?
  public var hidden: Bool?
  public var id: String
  public var isArchived: Bool?
  public var isAsyncOperationOngoing: Bool?
  public var isFlagged: Bool?
  public var isProcessing: Bool?
  public var labels: [String]?
  public var lastFinalMessageId: String?
  public var lastMessageAt: Double?
  public var lastMessageRole: String?
  public var messageCount: Int?
  public var model: String?
  public var name: String?
  public var preview: String?
  public var sessionStatus: String?
  public var workspaceId: String?
  public var workspaceName: String?

  public init(
    id: String,
    createdAt: Double? = nil,
    currentStatus: RemoteSessionStatus? = nil,
    hasUnread: Bool? = nil,
    hidden: Bool? = nil,
    isArchived: Bool? = nil,
    isAsyncOperationOngoing: Bool? = nil,
    isFlagged: Bool? = nil,
    isProcessing: Bool? = nil,
    labels: [String]? = nil,
    lastFinalMessageId: String? = nil,
    lastMessageAt: Double? = nil,
    lastMessageRole: String? = nil,
    messageCount: Int? = nil,
    model: String? = nil,
    name: String? = nil,
    preview: String? = nil,
    sessionStatus: String? = nil,
    workspaceId: String? = nil,
    workspaceName: String? = nil
  ) {
    self.createdAt = createdAt
    self.currentStatus = currentStatus
    self.hasUnread = hasUnread
    self.hidden = hidden
    self.id = id
    self.isArchived = isArchived
    self.isAsyncOperationOngoing = isAsyncOperationOngoing
    self.isFlagged = isFlagged
    self.isProcessing = isProcessing
    self.labels = labels
    self.lastFinalMessageId = lastFinalMessageId
    self.lastMessageAt = lastMessageAt
    self.lastMessageRole = lastMessageRole
    self.messageCount = messageCount
    self.model = model
    self.name = name
    self.preview = preview
    self.sessionStatus = sessionStatus
    self.workspaceId = workspaceId
    self.workspaceName = workspaceName
  }
}

public struct RemoteSessionStatus: Codable, Equatable, Hashable, Sendable {
  public var message: String
  public var statusType: String?

  public init(message: String, statusType: String? = nil) {
    self.message = message
    self.statusType = statusType
  }
}
