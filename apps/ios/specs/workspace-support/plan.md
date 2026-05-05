# Implementation Plan: Workspace Support

**Branch**: `main` | **Date**: 2026-05-05 | **Spec**: [/Users/laksh/Developer/craft-agents-oss/apps/ios/specs/workspace-support/spec.md](/Users/laksh/Developer/craft-agents-oss/apps/ios/specs/workspace-support/spec.md)
**Input**: Feature specification from `/Users/laksh/Developer/craft-agents-oss/apps/ios/specs/workspace-support/spec.md`

## Summary

Introduce first-class workspace support by replacing the proof-of-concept single `Pairing` route with a persisted workspace list, a persisted current workspace selection, and a simple app-shell workspace button. App launch routes to connection setup only when no saved workspaces exist; otherwise it opens the current workspace. The top-leading workspace button appears above every tab, opens a simple switcher, and offers switching, add-workspace, and current-workspace logout. Adding a workspace reuses `ConnectionFeature` in a dismissible sheet.

## Technical Context

**Language/Version**: Swift tools 6.3  
**Primary Dependencies**: UIKit, ComposableArchitecture2, Sharing, SQLiteData, StructuredQueries via SQLiteData, existing Craft companion RPC client  
**Storage**: SQLiteData for saved workspace records; Sharing `@Shared(.appStorage(...))` for the single selected workspace ID preference  
**Testing**: Existing XCTest/TCA test target, reducer tests, database-backed unit tests where needed, FlowDeck build/test/smoke verification  
**Target Platform**: iOS 26.0 app with Mac Catalyst support  
**Project Type**: Mobile app under `/Users/laksh/Developer/craft-agents-oss/apps/ios`  
**Performance Goals**: Launch routing uses local persisted workspace state immediately; workspace switcher opens without a network round trip; switching avoids displaying previous-workspace content as current  
**Constraints**: Keep workspace UI simple; preserve companion-client model; use FlowDeck for Apple platform verification; avoid direct Apple CLI tooling; prefer tight domain models without premature abstractions  
**Scale/Scope**: One Package.swift with small modules following the isowords style: `ClientModels`, `Database`, `RPCClient`, `ConnectionFeature`, and `AppFeature`; one root app shell, one workspace switcher, one add-workspace sheet, saved workspace persistence, selected workspace persistence, current Sessions tab re-scoping

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Companion Client, Not Replacement Server**: Pass. Workspaces remain remote destinations owned by the Craft server. The app stores local access metadata only and does not implement server behavior.
- **II. Sessions and Chat Are the Core Product**: Pass. Workspace support is scoped to make Sessions reliable and correctly scoped. No broader management surface is introduced.
- **III. Resilient Workspace Context**: Pass. The feature exists to make active workspace identity visible, persisted, switchable, and safe across launches and logout.
- **IV. Native UI for Bounded Actions, Agent-Driven for Complex Work**: Pass. Workspace switching, adding a connection, and logout are frequent bounded actions, so native UI is appropriate.
- **V. Strive for Tight Domain Modeling**: Pass. Plan uses explicit workspace records, current selection, app route, add-workspace sheet, and switcher states instead of a single optional pairing.
- **VI. Prefer Duplication Over Premature Abstraction**: Pass. Reuse `ConnectionFeature` for add/setup, but avoid creating generic account/workspace management abstractions beyond this feature.
- **VII. Testing in Some Form**: Pass. Reducer/database tests cover route, selection, add, and logout behavior; FlowDeck provides build/test and simple smoke verification.

**Post-design re-check**: Pass. Phase 1 design preserves the same gates. No constitution violations or complexity waivers are required.

## Project Structure

### Documentation (this feature)

```text
/Users/laksh/Developer/craft-agents-oss/apps/ios/specs/workspace-support/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── workspace-ui-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
/Users/laksh/Developer/craft-agents-oss/apps/ios/
├── Package.swift                         # Single package defining all app modules
├── project.yml                           # App target depends on AppFeature product
├── Sources/
│   ├── ClientModels/                     # Core mobile domain and DTO models
│   │   ├── Workspace.swift
│   │   └── RemoteModels.swift
│   ├── Database/                         # Extractable database module depending on ClientModels
│   │   ├── Schema.swift                  # SQLiteData bootstrap and WorkspaceRecord schema/migration
│   │   └── WorkspacePersistence.swift
│   ├── RPCClient/                        # Existing companion RPC protocol/client/dependency
│   ├── ConnectionFeature/                # Connection setup feature and view controller
│   └── AppFeature/                       # App shell, tabs, sessions, root view controller
│       ├── AppFeature.swift
│       ├── AppRoot.swift
│       ├── AppViewController.swift
│       ├── TabFeature.swift
│       ├── TabViewController.swift
│       ├── SessionsFeature.swift
│       └── SessionsViewController.swift
└── Tests/
    ├── DatabaseTests/                    # Database module tests
    ├── ConnectionFeatureTests/           # Connection module tests
    ├── AppFeatureTests/                  # App routing, tabs, sessions tests
    └── RPCClientTests/                   # Existing RPC protocol/client tests
```

**Structure Decision**: Move from one broad target to small modules in the same `Package.swift`, following the isowords style of feature, model, and database modules. Put core shared mobile types in `ClientModels`. Put SQLiteData bootstrap, schema, migrations, and persistence in `Database`, which depends on `ClientModels`. Put the existing connection flow in `ConnectionFeature`. Keep app composition, tabs, and Sessions in `AppFeature`. Tests live beside the module they verify. This modularization must happen before workspace feature/UI work so the database and connection boundaries are settled first.

## Implementation Stages

### Stage 1: SQLiteData Foundation

Set up the module layout and database before implementing workspace routing or UI. Add `ClientModels`, `Database`, `RPCClient`, `ConnectionFeature`, and `AppFeature` targets in the single `Package.swift`. Add the app database bootstrap, initial migration, and `WorkspaceRecord` schema in the `Database` module. Add focused `DatabaseTests` that can insert, fetch, enforce the uniqueness rule, and delete saved workspace records. This stage must be complete before replacing the proof-of-concept `Pairing` flow.

### Stage 2: Workspace Selection Preference

Add a single selected-workspace ID preference in user defaults via Sharing. Validate that launch can resolve the preference against saved workspace records, fall back to another saved workspace when stale, and route to setup when no saved records exist. Keep this as a small preference, not a database table.

### Stage 3: App Routing Cleanup

Replace the single optional `Pairing` root decision with workspace-aware app state: no saved workspaces routes to setup; a resolved current workspace routes to the main tabs. Keep the current workspace as an explicit value handed to child features so previous-workspace content is not presented as current after switching.

### Stage 4: Connection Flow Reuse

Reuse `ConnectionFeature` for both first setup and add-workspace. First setup is the root route and is not dismissible. Add-workspace is presented from the main app as a dismissible sheet; cancelling leaves the selected workspace untouched, while success saves a `WorkspaceRecord` and makes it available to the switcher.

### Stage 5: Simple Workspace Switcher UI

Add a top-leading workspace button owned by the shared tab/app shell. Tapping it presents a simple switcher with the saved workspace list, the current workspace indication, Add Workspace, and Logout Current Workspace. Avoid building a full workspace management screen.

### Stage 6: Logout and Session Re-scope

Implement current-workspace logout from the switcher. Removing the last workspace routes back to setup; removing one of many selects a safe fallback. Re-scope `SessionsFeature` to the new current workspace and remove the proof-of-concept per-session-screen logout/re-pair control.

### Stage 7: Verification

Cover routing, persistence, switch, add, cancel, and logout behavior with reducer/database tests. Run FlowDeck build/test, then perform the quickstart smoke paths for first setup, return to current workspace, add workspace, switch workspace, and logout current workspace.

## Complexity Tracking

No constitution violations or additional complexity waivers are required.
