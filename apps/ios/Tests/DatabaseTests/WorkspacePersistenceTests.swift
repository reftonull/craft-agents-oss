import Database
import Dependencies
import DependenciesTestSupport
import Foundation
import Sharing
import SQLiteData
import Testing

@Suite(
  "WorkspacePersistence",
  .dependencies {
    $0.defaultAppStorage = .inMemory
    try $0.bootstrapDatabase()
  }
)
struct WorkspacePersistenceTests {
  @Dependency(\.defaultDatabase) var database

  @Test
  func `inserts and fetches workspaces`() async throws {
    let workspace = try testWorkspace(
      id: "00000000-0000-0000-0000-000000000001",
      remoteWorkspaceID: "workspace-1",
      displayName: "Personal",
      serverURL: "ws://desktop.local:9100/",
      openedAt: 100
    )

    try await database.write { db in
      try Workspace.insert { workspace }.execute(db)
    }
    let fetched = try await database.read { db in
      try Workspace.fetchAll(db)
    }

    #expect(fetched == [workspace])
  }

  @Test
  func `enforces uniqueness on normalized server URL and remote workspace ID`() async throws {
    let original = try testWorkspace(
      id: "00000000-0000-0000-0000-000000000011",
      remoteWorkspaceID: "workspace-1",
      displayName: "Original",
      serverURL: "ws://desktop.local:9100/",
      openedAt: 100
    )
    let duplicate = try testWorkspace(
      id: "00000000-0000-0000-0000-000000000012",
      remoteWorkspaceID: "workspace-1",
      displayName: "Duplicate",
      serverURL: "ws://DESKTOP.local:9100",
      openedAt: 200
    )

    try await database.write { db in
      try Workspace.insert { original }.execute(db)
    }
    await #expect(throws: (any Error).self) {
      try await database.write { db in
        try Workspace.insert { duplicate }.execute(db)
      }
    }
    let fetched = try await database.read { db in
      try Workspace.fetchAll(db)
    }

    #expect(fetched == [original])
  }

  @Test
  func `deletes a workspace and resolves fallback selection from fetched workspaces`() async throws {
    let older = try testWorkspace(
      id: "00000000-0000-0000-0000-000000000021",
      remoteWorkspaceID: "workspace-older",
      displayName: "Older",
      serverURL: "ws://desktop.local:9100",
      openedAt: 100
    )
    let newer = try testWorkspace(
      id: "00000000-0000-0000-0000-000000000022",
      remoteWorkspaceID: "workspace-newer",
      displayName: "Newer",
      serverURL: "ws://desktop.local:9100",
      openedAt: 200
    )

    try await database.write { db in
      try Workspace.insert { older }.execute(db)
      try Workspace.insert { newer }.execute(db)
      try Workspace.delete(newer).execute(db)
    }
    let fetched = try await database.read { db in
      try Workspace.fetchAll(db).sortedByFallbackPriority()
    }
    let fallback = fetched.first { $0.id != newer.id }

    #expect(fetched == [older])
    #expect(fallback == older)
  }
}

private func testWorkspace(
  id rawID: String,
  remoteWorkspaceID: String,
  displayName: String,
  serverURL: String,
  openedAt: TimeInterval
) throws -> Workspace {
  try Workspace(
    id: #require(UUID(uuidString: rawID)),
    remoteWorkspaceID: remoteWorkspaceID,
    displayName: displayName,
    serverURL: serverURL,
    tokenReference: "secret-token",
    createdAt: Date(timeIntervalSince1970: openedAt - 20),
    updatedAt: Date(timeIntervalSince1970: openedAt - 10),
    lastOpenedAt: Date(timeIntervalSince1970: openedAt)
  )
}

private extension [Workspace] {
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
