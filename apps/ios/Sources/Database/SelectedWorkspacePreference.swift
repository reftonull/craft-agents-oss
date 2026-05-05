import Foundation
import Sharing

public extension SharedKey where Self == AppStorageKey<Workspace.ID?> {
  static var agentsMobileSelectedWorkspaceID: Self {
    .appStorage("agentsMobileSelectedWorkspaceID")
  }
}
