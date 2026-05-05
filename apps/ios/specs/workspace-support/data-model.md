# Data Model: Workspace Support

## WorkspaceRecord

Represents a saved workspace available on this device. This is the only new durable database-backed entity required for the feature.

### Fields

- `id`: Stable local record identifier.
- `remoteWorkspaceID`: Workspace identifier reported by the remote Craft Agents server.
- `displayName`: User-recognizable workspace name shown in the app-shell button and switcher.
- `serverURL`: Remote server URL used to reconnect.
- `tokenReference`: Credential/token value or reference used by the existing connection flow for this feature slice.
- `remoteSlug`: Optional remote workspace slug when available.
- `createdAt`: When the workspace was first saved locally.
- `updatedAt`: When local workspace metadata was last refreshed.
- `lastOpenedAt`: Optional timestamp used to pick a safe fallback workspace.

### Validation Rules

- `remoteWorkspaceID` MUST be non-empty.
- `serverURL` MUST be a valid reachable connection destination according to the connection setup validation rules.
- `displayName` MUST be non-empty; if the remote name is unavailable, use the remote workspace ID as fallback display identity.
- Saved workspaces MUST have a uniqueness rule on the combination of normalized `serverURL` and `remoteWorkspaceID`.
- `tokenReference` MUST NOT be shown in user-visible labels, logs, or example output.

### Relationships

- A `WorkspaceRecord` may be referenced by the selected workspace preference.
- A `WorkspaceRecord` scopes the Sessions tab and future session/chat/label/resource data.
- Multiple `WorkspaceRecord`s may share the same `serverURL` when they represent different remote workspaces on the same server.

## SelectedWorkspacePreference

Represents which saved workspace the app opens by default. This is a single small value in user defaults, not a database record.

### Fields

- `workspaceRecordID`: Optional local record identifier of the selected workspace.

### Validation Rules

- If `workspaceRecordID` is present, it MUST match a saved `WorkspaceRecord` before the app opens main tabs.
- If `workspaceRecordID` is missing or points to a removed workspace, the app MUST choose a safe fallback from saved workspaces or route to setup when none exist.
- The selection MUST be updated when a user switches workspace, completes first setup, or logs out of the selected workspace.
- Cancelling add-workspace MUST NOT change the selected workspace preference.

### Relationships

- Points to at most one `WorkspaceRecord`.
- Drives which workspace the app attempts to open on launch.
