# Research: Workspace Support

## Decision: Persist saved workspaces in SQLiteData

**Rationale**: The user explicitly wants saved workspaces to persist across app runs in a database. SQLiteData is already a dependency of the iOS target and aligns with the broader Agents Mobile foundations direction. Persisting saved workspaces as records gives the app a future-proof base for multiple workspaces, local metadata, reconnect status, and later cache-scoped data without keeping the proof-of-concept single `Pairing` shape.

**Alternatives considered**:

- Continue storing a single `Pairing` in app storage: rejected because it cannot represent multiple saved workspaces, switching, or current-workspace logout cleanly.
- Store all workspaces in app storage: rejected because the requirement calls for database persistence for workspaces and this would not establish the needed workspace data boundary.
- Add a generic account-management store: rejected as premature abstraction for this small workflow.

## Decision: Modularize like isowords in a single Package.swift

**Rationale**: Workspace support introduces durable core types, database persistence, and connection reuse. Keeping all of that in one broad target would make extraction harder later. The plan should follow the isowords style: small targets in one package, with database-backed client models grouped with database bootstrap and migrations. `Database` owns core mobile types, SQLiteData-backed models, remote DTOs, and SQLiteData bootstrap; `RPCClient` owns the companion RPC client; `ConnectionFeature` owns setup UI/logic; and `AppFeature` composes the app shell, tabs, and sessions.

**Alternatives considered**:

- Keep `AgentsMobileCore` as the only target: rejected because database, connection, and core model boundaries would remain unsettled proof-of-concept structure.
- Create multiple packages immediately: rejected because a single Package.swift is simpler and matches the requested isowords-style modularization.
- Put database files in an app feature directory: rejected because the database module should be extractable and independently testable.

## Decision: Persist only the current workspace selection in Sharing app storage

**Rationale**: The selected workspace is a small piece of app preference state and the user explicitly said it does not need to be in the database. Sharing app storage is already used in the app and is appropriate for restoring the current workspace ID at launch. The saved workspace record remains the source of truth for connection metadata.

**Alternatives considered**:

- Store current selection in the database: rejected because it is unnecessary for the stated requirement and makes launch routing depend on mutable data and preference state in one place.
- Derive the current workspace from most recent workspace: rejected because it is less explicit and can surprise users.

## Decision: Replace `Pairing?` route with explicit workspace app state

**Rationale**: The current proof-of-concept `Pairing?` represents no-workspace versus one-workspace, but it cannot distinguish saved workspaces, selected workspace, unavailable selection, add-workspace flow, or current-workspace logout. Explicit route and selection states make invalid states easier to avoid: no workspaces routes to setup; saved current workspace routes to main; missing selection falls back safely.

**Alternatives considered**:

- Extend `Pairing` with optional fields: rejected because it would continue to mix connection metadata, selected workspace identity, and route state.
- Introduce a broad session/workspace sync engine now: rejected as too large for the requested simple workspace support slice.

## Decision: Keep the app-shell control simple: top-leading button plus switcher

**Rationale**: The user requested a simple top-leading button showing the current workspace. A button in the shared tab/app shell keeps context visible from every tab without requiring each feature to own workspace UI. The switcher should show saved workspaces, indicate the current one, and offer only Add Workspace and Logout Current Workspace actions.

**Alternatives considered**:

- Full workspace management screen: rejected because the user asked to keep it simple.
- Per-tab workspace controls: rejected because it duplicates UI and risks inconsistent behavior.
- Context menu only: rejected because add/logout flows and recoverable errors need a clearer presentation surface.

## Decision: Reuse `ConnectionFeature` for first setup and add-workspace sheet

**Rationale**: The existing connection flow already validates URL/token/workspace input, discovers workspaces, verifies the selected workspace, and emits a completion delegate. Reusing it preserves behavior and avoids inventing a second add-workspace flow. The parent feature decides whether completion routes to main setup or dismisses a sheet and updates the workspace list.

**Alternatives considered**:

- Fork a separate `AddWorkspaceFeature`: rejected until duplication proves the flows need materially different behavior.
- Create a highly generic connection coordinator: rejected as premature abstraction.

## Decision: Logout removes local access for the current workspace only

**Rationale**: The user specifically requested logout of the current workspace from the switcher. Removing local access keeps this feature bounded and avoids implying remote deletion. If the final workspace is removed, app state returns to first-time connection setup. If other workspaces remain, the app selects a safe fallback and re-scopes tabs.

**Alternatives considered**:

- Allow logging out any workspace from the switcher: rejected for the first slice because it complicates confirmation and edge cases beyond the requested simple flow.
- Remote workspace deletion: rejected because mobile is a companion client and must not manage server-owned workspace lifecycle.

## Decision: Testing includes reducer/database tests and a FlowDeck smoke path

**Rationale**: The constitution requires testing in some form for behavior-changing work. Reducer tests are best for route, switcher, add sheet, and logout state transitions. Database-backed tests are best for saved workspace persistence. A FlowDeck smoke path verifies that the app launches, setup routes correctly, and the shared workspace button appears after setup.

**Alternatives considered**:

- Manual-only verification: rejected because the state transitions are important and testable.
- Full end-to-end automation for every edge case: rejected as too heavy for this simple workspace-support slice.
