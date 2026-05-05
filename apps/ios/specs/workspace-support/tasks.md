---
description: "Task list for Workspace Support implementation"
---

# Tasks: Workspace Support

**Input**: Design documents from `/Users/laksh/Developer/craft-agents-oss/apps/ios/specs/workspace-support/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/workspace-ui-contract.md`, `quickstart.md`

**Tests**: Included because the constitution and plan require testing in some form for behavior-changing work. Test tasks live in the test target for the module they verify.

**Organization**: Tasks are grouped by user story after a blocking modularization and SQLiteData foundation. The module layout follows the isowords style with a single `Package.swift`, small feature/model/database targets, and matching test targets.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel after dependencies are satisfied because it touches different files or independent checks
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)
- All descriptions include exact file paths

## Path Conventions

- iOS project root: `/Users/laksh/Developer/craft-agents-oss/apps/ios`
- Database module: `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/Database/`
- RPC module: `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/RPCClient/`
- Connection module: `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/ConnectionFeature/`
- App shell module: `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/`
- Module tests: `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/<ModuleName>Tests/`
- Feature docs: `/Users/laksh/Developer/craft-agents-oss/apps/ios/specs/workspace-support/`

## Phase 1: Setup (Modular Package Preparation)

**Purpose**: Establish and compile the module layout before implementing workspace persistence or UI.

- [X] T001 Update `/Users/laksh/Developer/craft-agents-oss/apps/ios/Package.swift` to define `Database`, `RPCClient`, `ConnectionFeature`, and `AppFeature` targets/products in one package
- [X] T002 Update `/Users/laksh/Developer/craft-agents-oss/apps/ios/Package.swift` so `Database` owns shared models and depends on `SQLiteData`, `Sharing`, and StructuredQueries support from SQLiteData
- [X] T003 Update `/Users/laksh/Developer/craft-agents-oss/apps/ios/Package.swift` so `ConnectionFeature` depends on `Database`, `RPCClient`, and `ComposableArchitecture2`
- [X] T004 Update `/Users/laksh/Developer/craft-agents-oss/apps/ios/Package.swift` so `AppFeature` depends on `Database`, `RPCClient`, `ConnectionFeature`, `ComposableArchitecture2`, and `Sharing`
- [X] T005 Update `/Users/laksh/Developer/craft-agents-oss/apps/ios/Package.swift` to add `DatabaseTests`, `ConnectionFeatureTests`, `AppFeatureTests`, and `RPCClientTests` test targets with module-specific dependencies
- [X] T006 Update `/Users/laksh/Developer/craft-agents-oss/apps/ios/project.yml` so the app target depends on the `AppFeature` package product instead of the old broad product
- [X] T007 Update `/Users/laksh/Developer/craft-agents-oss/apps/ios/project.yml` so the test target reads from `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests` and can import the module products it tests
- [X] T008 Create `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/Database/Workspace.swift` for shared workspace domain types
- [X] T009 Create `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/Database/RemoteModels.swift` for shared remote workspace/session DTOs
- [X] T010 Create `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/Database/Schema.swift` for SQLiteData bootstrap, migrations, and workspace schema
- [X] T011 Create `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/Database/SelectedWorkspacePreference.swift` for the selected workspace shared key
- [X] T012 Move existing RPC source files from `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AgentsMobile/RPC/` to `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/RPCClient/`
- [X] T013 Move existing connection files from `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AgentsMobile/ConnectionFeature.swift` and `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AgentsMobile/ConnectionViewController.swift` to `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/ConnectionFeature/`
- [X] T014 Move app shell and sessions files from `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AgentsMobile/` to `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/`
- [X] T015 Move existing RPC tests from `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AgentsMobileTests/RPC/` to `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/RPCClientTests/`
- [X] T016 Move existing connection tests from `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AgentsMobileTests/ConnectionFeatureTests.swift` to `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/ConnectionFeatureTests/ConnectionFeatureTests.swift`
- [X] T017 Move existing app and sessions tests from `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AgentsMobileTests/` to `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/`
- [X] T018 Create `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/DatabaseTests/WorkspacePersistenceTests.swift` for database-backed workspace persistence tests
- [X] T019 Move `RemoteWorkspace`, `RemoteSession`, and `RemoteSessionStatus` into `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/Database/RemoteModels.swift`
- [X] T020 Fix module imports after the split in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/RPCClient/`
- [X] T021 Fix module imports after the split in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/ConnectionFeature/`
- [X] T022 Fix module imports after the split in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/`
- [X] T023 Verify module-specific test targets import `Database`, `RPCClient`, `ConnectionFeature`, and `AppFeature` and compile via FlowDeck in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/AppFeatureTests.swift`

**Checkpoint**: The package is modularized, module imports are fixed, and `flowdeck build`/`flowdeck test` pass before database behavior is implemented.

---

## Phase 2: Foundational (Database Prerequisites)

**Purpose**: Establish SQLiteData and workspace persistence before changing routing or UI.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Tests for Workspace Persistence

- [X] T024 [P] Add failing tests for inserting and fetching SQLiteData-backed `Workspace` values in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/DatabaseTests/WorkspacePersistenceTests.swift`
- [X] T025 [P] Add failing tests for the `Workspace` uniqueness rule on normalized server URL plus remote workspace ID in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/DatabaseTests/WorkspacePersistenceTests.swift`
- [X] T026 [P] Add failing tests for deleting a saved workspace and resolving fallback selection in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/DatabaseTests/WorkspacePersistenceTests.swift`
- [X] T027 [P] Define selected workspace user-defaults shared key; direct read/write/clear test omitted after review because it only tests Sharing's app-storage behavior

### Foundational Implementation

- [X] T028 Define saved/current workspace domain types beyond the temporary `Pairing` bridge in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/Database/Workspace.swift`
- [X] T029 Implement `bootstrapDatabase()` using SQLiteData and register the initial migrator in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/Database/Schema.swift`
- [X] T030 Define `Workspace` as the SQLiteData-backed client model in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/Database/Workspace.swift`
- [X] T031 Add the initial `Workspace` migration with a uniqueness rule for normalized server URL plus remote workspace ID in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/Database/Schema.swift`
- [X] T032 Verify saved workspace insert, fetch, uniqueness, delete, and fallback behavior directly through SQLiteData APIs in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/DatabaseTests/WorkspacePersistenceTests.swift`
- [X] T033 Implement the selected workspace ID `@Shared(.appStorage(...))` key for direct feature usage in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/Database/SelectedWorkspacePreference.swift`
- [X] T034 Wire `prepareDependencies` and `bootstrapDatabase()` at app startup in `/Users/laksh/Developer/craft-agents-oss/apps/ios/App/AgentsMobileApp.swift`
- [X] T035 Run FlowDeck tests for completed database persistence behavior from `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/DatabaseTests/WorkspacePersistenceTests.swift`

**Checkpoint**: SQLiteData is bootstrapped, saved workspaces persist in the `Database` module, and selected workspace ID persists as a single user-defaults preference.

---

## Phase 3: User Story 1 - First Workspace Setup (Priority: P1) 🎯 MVP

**Goal**: A new user with no saved workspaces sees connection setup, completes setup, saves the workspace, selects it, and lands in main app content.

**Independent Test**: Start with no saved workspaces, open the app, complete valid connection setup, and verify the app saves and opens the new workspace.

### Tests for User Story 1

- [X] T036 [P] [US1] Add failing app route test for no saved workspaces showing onboarding in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/AppFeatureTests.swift`
- [X] T037 [P] [US1] Add failing app route test for connection completion saving a workspace and selecting it in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/AppFeatureTests.swift`
- [X] T038 [P] [US1] Add failing connection test for invalid connection preserving setup and recoverable error state in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/ConnectionFeatureTests/ConnectionFeatureTests.swift`

### Implementation for User Story 1

- [X] T039 [US1] Replace single optional `Pairing` launch decision with saved-workspace lookup in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/AppFeature.swift`
- [X] T040 [US1] Convert successful first setup into a saved `Workspace` plus selected workspace preference update in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/AppFeature.swift`
- [X] T041 [US1] Preserve root connection setup as non-dismissible onboarding when no saved workspaces exist in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/AppViewController.swift`
- [X] T042 [US1] Ensure `ConnectionFeature` exposes enough remote workspace display data to save a recognizable workspace in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/ConnectionFeature/ConnectionFeature.swift`
- [X] T043 [US1] Update first-setup copy and failure display if needed in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/ConnectionFeature/ConnectionViewController.swift`

**Checkpoint**: User Story 1 is fully functional and testable independently as the first-launch MVP.

---

## Phase 4: User Story 2 - Return to Current Workspace (Priority: P1)

**Goal**: A returning user opens directly into the selected saved workspace with clear workspace context.

**Independent Test**: Save a workspace, select it, terminate/relaunch, and verify the main app opens scoped to that workspace.

### Tests for User Story 2

- [X] T044 [P] [US2] Add failing test for valid selected workspace launching main route in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/AppFeatureTests.swift`
- [ ] T045 [P] [US2] Add failing test for stale selected workspace falling back to a saved workspace in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/AppFeatureTests.swift`
- [X] T046 [P] [US2] Add failing test for `SessionsFeature` loading sessions from the current workspace record in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/SessionsFeatureTests.swift`

### Implementation for User Story 2

- [X] T047 [US2] Add explicit current workspace state to main app routing in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/AppFeature.swift`
- [X] T048 [US2] Pass the resolved current workspace into `TabFeature.State` instead of proof-of-concept `Pairing` in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/TabFeature.swift`
- [X] T049 [US2] Pass the resolved current workspace into `SessionsFeature.State` in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/SessionsFeature.swift`
- [X] T050 [US2] Update session-loading connection request to use current workspace record fields in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/SessionsFeature.swift`
- [X] T051 [US2] Update Sessions status text to show the workspace display name or recognizable identity in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/SessionsViewController.swift`
- [X] T074 [US2] Remove proof-of-concept Logout/Re-pair navigation item from `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/SessionsViewController.swift`
- [X] T075 [US2] Remove obsolete repair delegate plumbing from `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/SessionsFeature.swift`

**Checkpoint**: User Stories 1 and 2 support first launch and return launch without repeating setup.

---

## Phase 5: User Story 3 - Switch Workspace from Any Tab (Priority: P2)

**Goal**: A user sees a top-leading workspace button in the shared app shell and can switch workspaces globally.

**Independent Test**: Save two workspaces, tap the top-leading workspace button, select another workspace, and verify all tabs reflect the new workspace.

### Tests for User Story 3

- [ ] T052 [P] [US3] Add failing reducer test for workspace switch updating current workspace and selected preference in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/TabFeatureTests.swift`
- [ ] T053 [P] [US3] Add failing reducer test for switching workspaces resetting or re-scoping Sessions state in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/TabFeatureTests.swift`
- [ ] T054 [P] [US3] Add UI contract coverage notes for top-leading button and switcher in `/Users/laksh/Developer/craft-agents-oss/apps/ios/specs/workspace-support/contracts/workspace-ui-contract.md`

### Implementation for User Story 3

- [ ] T055 [US3] Add saved workspace list, current workspace, and switcher presentation state to `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/TabFeature.swift`
- [ ] T056 [US3] Implement workspace switch action handling and selected preference updates in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/TabFeature.swift`
- [ ] T057 [US3] Add top-leading workspace button owned by the shared tab shell in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/TabViewController.swift`
- [ ] T058 [US3] Implement simple workspace switcher presentation with saved workspace list and current checkmark in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/TabViewController.swift`
- [ ] T059 [US3] Ensure workspace switching reconstructs or resets child tab state so old session content is not presented as current in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/TabFeature.swift`

**Checkpoint**: The current workspace is visible from the shared app shell, and switching applies globally.

---

## Phase 6: User Story 4 - Add Workspace While Already Signed In (Priority: P2)

**Goal**: A signed-in user can add another workspace from the switcher using a dismissible connection sheet without losing current context.

**Independent Test**: Open the switcher, tap Add Workspace, cancel and verify current workspace remains, then complete add-workspace and verify the new workspace is available.

### Tests for User Story 4

- [ ] T060 [P] [US4] Add failing reducer test for presenting and cancelling add-workspace sheet without changing selected workspace in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/TabFeatureTests.swift`
- [ ] T061 [P] [US4] Add failing reducer test for successful add-workspace saving the new workspace and listing it in the switcher in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/TabFeatureTests.swift`
- [ ] T062 [P] [US4] Add failing add-workspace test that exercises the workspace uniqueness rule in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/DatabaseTests/WorkspacePersistenceTests.swift`

### Implementation for User Story 4

- [ ] T063 [US4] Add add-workspace sheet child state and delegate handling to `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/TabFeature.swift`
- [ ] T064 [US4] Present `ConnectionViewController` as a dismissible sheet from Add Workspace in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/TabViewController.swift`
- [ ] T065 [US4] Add a cancel/dismiss affordance for sheet presentation only in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/ConnectionFeature/ConnectionViewController.swift`
- [ ] T066 [US4] Save successful add-workspace completion without changing selection on cancel in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/TabFeature.swift`
- [ ] T067 [US4] Refresh switcher workspace rows after add-workspace success in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/TabViewController.swift`

**Checkpoint**: Users can add another workspace from the main app while preserving current context.

---

## Phase 7: User Story 5 - Log Out of a Workspace (Priority: P3)

**Goal**: A user can log out of the current workspace from the switcher and the app remains in a valid route.

**Independent Test**: Save one or more workspaces, log out of the current workspace, and verify fallback selection or first-time setup routing.

### Tests for User Story 5

- [ ] T068 [P] [US5] Add failing reducer test for logout current workspace with multiple saved workspaces selecting a fallback in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/TabFeatureTests.swift`
- [ ] T069 [P] [US5] Add failing app route test for logout of final workspace returning to setup in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/AppFeatureTests.swift`
- [ ] T070 [P] [US5] Add UI contract coverage notes for logout-current-workspace copy in `/Users/laksh/Developer/craft-agents-oss/apps/ios/specs/workspace-support/contracts/workspace-ui-contract.md`

### Implementation for User Story 5

- [ ] T071 [US5] Add Logout Current Workspace action to the workspace switcher UI in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/TabViewController.swift`
- [ ] T072 [US5] Implement current workspace deletion and fallback selection from the switcher in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/TabFeature.swift`
- [ ] T073 [US5] Ensure final-workspace logout returns to setup through shared workspace selection and fetched workspace records in `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AppFeature/AppFeature.swift`

**Checkpoint**: Current-workspace logout works for both single-workspace and multi-workspace cases.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Verify the complete modular workspace flow, update docs, and remove proof-of-concept leftovers.

- [ ] T076 [P] Update module layout and workspace support notes in `/Users/laksh/Developer/craft-agents-oss/apps/ios/README.md`
- [ ] T077 [P] Update generated agent context active technologies and recent changes in `/Users/laksh/Developer/craft-agents-oss/apps/ios/CLAUDE.md`
- [ ] T078 [P] Remove empty legacy source/test directories under `/Users/laksh/Developer/craft-agents-oss/apps/ios/Sources/AgentsMobile/` and `/Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AgentsMobileTests/`
- [ ] T079 Run `swiftformat .` and `swiftformat --lint .` from `/Users/laksh/Developer/craft-agents-oss/apps/ios`
- [ ] T080 Run `flowdeck build` from `/Users/laksh/Developer/craft-agents-oss/apps/ios`
- [ ] T081 Run `flowdeck test` from `/Users/laksh/Developer/craft-agents-oss/apps/ios`
- [ ] T082 Execute Smoke Path 1 and Smoke Path 2 from `/Users/laksh/Developer/craft-agents-oss/apps/ios/specs/workspace-support/quickstart.md`
- [ ] T083 Execute Smoke Path 3 and Smoke Path 4 from `/Users/laksh/Developer/craft-agents-oss/apps/ios/specs/workspace-support/quickstart.md`
- [ ] T084 Execute Smoke Path 5 and regression checks from `/Users/laksh/Developer/craft-agents-oss/apps/ios/specs/workspace-support/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; can start immediately.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user stories because workspace records must exist before routing/UI changes.
- **User Story 1 (Phase 3)**: Depends on Foundational; provides MVP first setup.
- **User Story 2 (Phase 4)**: Depends on Foundational and integrates best after US1 route changes; provides return launch.
- **User Story 3 (Phase 5)**: Depends on US1 and US2; adds global switcher and workspace switching.
- **User Story 4 (Phase 6)**: Depends on US3; add-workspace is launched from the switcher.
- **User Story 5 (Phase 7)**: Depends on US3; logout is launched from the switcher and can be implemented before or after US4.
- **Polish (Phase 8)**: Depends on all desired user stories.

### User Story Dependencies

- **US1 First Workspace Setup**: MVP; required for first-time users.
- **US2 Return to Current Workspace**: Same priority as US1; completes launch behavior for returning users.
- **US3 Switch Workspace from Any Tab**: Requires saved workspace and current workspace model from US1/US2.
- **US4 Add Workspace While Already Signed In**: Requires the switcher from US3.
- **US5 Log Out of a Workspace**: Requires the switcher from US3.

### Within Each User Story

- Write failing tests first where listed.
- Keep tests in the module-specific test directory for the module being verified.
- Implement domain/state changes before UIKit rendering changes.
- Complete reducer behavior before smoke testing UI behavior.
- Keep each story independently verifiable at its checkpoint.

---

## Parallel Opportunities

- Package target updates T001 through T005 should be coordinated in one edit to `/Users/laksh/Developer/craft-agents-oss/apps/ios/Package.swift`.
- Module skeleton tasks T008 through T011 can run in parallel with project.yml updates after Package.swift direction is set.
- Phase 1 is complete; future task execution starts at Phase 2.
- Foundational tests T024 through T027 can be written in parallel now that module imports compile.
- Within each user story, test tasks marked [P] can be written in parallel before implementation.
- US4 and US5 can proceed in parallel after US3 if file conflicts in `TabFeature.swift` and `TabViewController.swift` are coordinated.
- Polish documentation tasks T076 and T077 can run in parallel before final verification commands.

## Parallel Example: Foundational Database Tests

```bash
Task T024: "Add failing tests for inserting and fetching Workspace values in /Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/DatabaseTests/WorkspacePersistenceTests.swift"
Task T025: "Add failing tests for the Workspace uniqueness rule on normalized server URL plus remote workspace ID in /Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/DatabaseTests/WorkspacePersistenceTests.swift"
Task T026: "Add failing tests for deleting a saved workspace and resolving fallback selection in /Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/DatabaseTests/WorkspacePersistenceTests.swift"
```

## Parallel Example: User Story 3

```bash
Task: "Add failing reducer test for workspace switch updating current workspace and selected preference in /Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/TabFeatureTests.swift"
Task: "Add failing reducer test for switching workspaces resetting or re-scoping Sessions state in /Users/laksh/Developer/craft-agents-oss/apps/ios/Tests/AppFeatureTests/TabFeatureTests.swift"
Task: "Add UI contract coverage notes for top-leading button and switcher in /Users/laksh/Developer/craft-agents-oss/apps/ios/specs/workspace-support/contracts/workspace-ui-contract.md"
```

---

## Implementation Strategy

### MVP First (Modular Foundation + US1 + US2)

1. Complete Phase 1 modular package setup.
2. Complete Phase 2 SQLiteData foundation in the `Database` module.
3. Complete US1 first workspace setup.
4. Complete US2 return to current workspace.
5. Stop and validate first launch plus returning launch before adding switcher behavior.

### Incremental Delivery

1. Modular package ready: `Database`, `RPCClient`, `ConnectionFeature`, and `AppFeature` compile independently. ✅
2. Foundation ready: saved workspaces persist in SQLiteData and selected workspace preference persists in user defaults.
3. US1: first-time setup saves and selects a workspace.
4. US2: returning launch opens current workspace.
5. US3: shared top-leading workspace button and switcher support switching.
6. US4: add workspace from the switcher using a dismissible connection sheet.
7. US5: logout current workspace from the switcher.
8. Polish: docs, formatting, FlowDeck build/test, quickstart smoke paths.

### Risk Controls

- Do not implement workspace UI before modularization, SQLiteData bootstrap, and persistence tests pass.
- Do not keep both proof-of-concept `Pairing` routing and new workspace routing as competing sources of truth.
- Do not expose token values in workspace labels, logs, screenshots, or docs.
- Do not add a full workspace management screen; keep the switcher simple.
- Do not let the `Database` module depend on `AppFeature` or `ConnectionFeature`; dependencies flow from app/features down to models and database.

## Notes

- [P] tasks use different files or are safe to prepare concurrently after prerequisites.
- User-story labels map to `spec.md` stories for traceability.
- FlowDeck is required for Apple platform build/test/smoke verification.
- Avoid direct Apple CLI tooling for this feature.
