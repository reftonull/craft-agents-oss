import Foundation

public struct Pairing: Codable, Equatable, Sendable {
  public var token: String
  public var url: URL
  public var workspaceID: String

  public init(
    token: String,
    url: URL,
    workspaceID: String
  ) {
    self.token = token
    self.url = url
    self.workspaceID = workspaceID
  }
}
