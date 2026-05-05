import Dependencies
import Foundation
import SQLiteData

public extension DependencyValues {
  mutating func bootstrapDatabase() throws {
    let database = try SQLiteData.defaultDatabase()
    var migrator = DatabaseMigrator()
    #if DEBUG
      migrator.eraseDatabaseOnSchemaChange = true
    #endif

    migrator.registerMigration("Create workspaces table") { db in
      try #sql("""
      CREATE TABLE "workspaces" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "remoteWorkspaceID" TEXT NOT NULL,
        "displayName" TEXT NOT NULL,
        "serverURL" TEXT NOT NULL,
        "tokenReference" TEXT NOT NULL,
        "remoteSlug" TEXT,
        "createdAt" TEXT NOT NULL,
        "updatedAt" TEXT NOT NULL,
        "lastOpenedAt" TEXT
      ) STRICT
      """)
      .execute(db)

      try #sql("""
      CREATE UNIQUE INDEX "index_workspaces_on_serverURL_remoteWorkspaceID"
      ON "workspaces"("serverURL", "remoteWorkspaceID")
      """)
      .execute(db)
    }

    try migrator.migrate(database)
    defaultDatabase = database
  }
}
