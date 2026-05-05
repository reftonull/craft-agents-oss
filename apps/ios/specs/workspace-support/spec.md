# Feature Specification: Workspace Support

**Feature Branch**: `workspace-support`  
**Created**: 2026-05-05  
**Status**: Draft  
**Input**: User description: "Introduce workspace support and clear up proof-of-concept workspace/connection behavior. On app open, show connection setup if no workspaces exist; otherwise open the current workspace. Every tab should have a simple top-leading button showing the current workspace. Tapping it should show a workspace switcher with options to switch workspaces, add a new workspace, and log out of the current workspace. Adding a workspace should reuse the connection flow in a dismissible sheet. Workspaces and the selected workspace must persist across app launches."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First Workspace Setup (Priority: P1)

A new user opens Agents Mobile with no saved workspaces and is guided directly into setting up a connection to a remote Craft Agents workspace.

**Why this priority**: Without this path, first-time users cannot enter the app or create the workspace context required by all other screens.

**Independent Test**: Start the app with no saved workspaces. Verify that the connection setup screen appears, a valid connection creates a saved workspace, and the user lands in that workspace.

**Acceptance Scenarios**:

1. **Given** no workspaces are saved, **When** the user opens the app, **Then** the app shows the connection setup screen instead of the main tabs.
2. **Given** the connection setup screen is shown, **When** the user enters valid remote server details and completes setup, **Then** the app saves the workspace, marks it as current, and opens the main app in that workspace.
3. **Given** the connection setup screen is shown, **When** the user enters invalid or unreachable connection details, **Then** the app shows a clear recoverable error and keeps the user in setup.

---

### User Story 2 - Return to Current Workspace (Priority: P1)

A returning user opens Agents Mobile and is taken directly into the workspace they were using last.

**Why this priority**: The app must feel like a dependable companion that preserves context across launches.

**Independent Test**: Save at least one workspace, select it, terminate and reopen the app. Verify that the app opens directly to the selected workspace and shows its identity in the app chrome.

**Acceptance Scenarios**:

1. **Given** at least one workspace is saved and one is selected, **When** the user opens the app, **Then** the app opens the main tabs scoped to the selected workspace.
2. **Given** the selected workspace cannot be reached, **When** the app opens, **Then** the app still shows the selected workspace context and presents a clear reconnect or recovery state.
3. **Given** the previously selected workspace is no longer available locally, **When** the user opens the app, **Then** the app chooses a safe fallback workspace if one exists or returns to connection setup if none exists.

---

### User Story 3 - Switch Workspace from Any Tab (Priority: P2)

A user can always see which workspace they are in via a simple top-leading button and switch to another saved workspace from any tab.

**Why this priority**: Workspace context affects every session, label, resource, and chat surface. Users need a consistent way to verify and change that context.

**Independent Test**: Save multiple workspaces, open each tab, and verify that a top-leading workspace button displays the current workspace and opens a switcher that changes the active workspace for the whole app.

**Acceptance Scenarios**:

1. **Given** the user is in the main app, **When** any tab is visible, **Then** a top-leading button displays the current workspace name or recognizable identity.
2. **Given** multiple workspaces are saved, **When** the user taps the workspace button, **Then** the app shows a simple workspace switcher with saved workspaces and indicates the current one.
3. **Given** the user selects a different workspace, **When** the switch completes, **Then** all tabs reflect the newly selected workspace and stale content from the previous workspace is not presented as current.

---

### User Story 4 - Add Workspace While Already Signed In (Priority: P2)

A user who is already in a workspace can add another workspace without losing their current app context.

**Why this priority**: Users may work across multiple remote servers or workspaces and should not need to reset the app to add another one.

**Independent Test**: Open the workspace control from the main app, choose to add a workspace, complete setup in a dismissible modal flow, and verify that the new workspace is saved and available for switching.

**Acceptance Scenarios**:

1. **Given** the user is in the main app, **When** they choose to add a workspace, **Then** the app presents the connection setup flow as a dismissible sheet.
2. **Given** the add-workspace sheet is open, **When** the user cancels, **Then** the sheet closes and the previous workspace remains current.
3. **Given** the add-workspace sheet is open, **When** the user completes a valid setup, **Then** the new workspace is saved and the user can switch to it.

---

### User Story 5 - Log Out of a Workspace (Priority: P3)

A user can log out of the current workspace when they no longer want it available on the device.

**Why this priority**: Workspace access must be user-controllable, especially on shared or changing devices.

**Independent Test**: Save one or more workspaces, log out of the current workspace from the workspace switcher, and verify that it is removed from the workspace list and no longer opens automatically.

**Acceptance Scenarios**:

1. **Given** multiple workspaces are saved, **When** the user logs out of the current workspace, **Then** the app removes that workspace and switches to another saved workspace or asks the user to choose one.
2. **Given** only one workspace is saved, **When** the user logs out of it, **Then** the app removes it and returns to the connection setup screen.
3. **Given** the workspace switcher is open, **When** the user chooses logout, **Then** the app clearly indicates that the action applies to the current workspace.

---

### Edge Cases

- The user cancels first-time connection setup before any workspace exists.
- The user tries to add a workspace that is already saved.
- A saved workspace has expired access or no longer exists on the remote server.
- The app is relaunched after the current workspace was removed.
- A workspace switch is requested while the current tab is loading or refreshing.
- Logging out fails to complete cleanly because local workspace data cannot be fully removed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST detect whether any workspaces are saved before deciding the initial route on launch.
- **FR-002**: The app MUST show connection setup as the initial experience when no workspaces are saved.
- **FR-003**: The app MUST open the selected workspace automatically when one or more workspaces are saved.
- **FR-004**: The app MUST persist saved workspaces across app launches.
- **FR-005**: The app MUST persist the currently selected workspace across app launches.
- **FR-006**: Every main tab MUST display the current workspace identity in a consistent top-leading button owned by the shared app shell.
- **FR-007**: Tapping the workspace button MUST open a simple workspace switcher.
- **FR-008**: The workspace switcher MUST list saved workspaces, identify the current workspace, and show actions to add a workspace and log out of the current workspace.
- **FR-009**: Selecting a workspace MUST update the active workspace for the whole app, not only the current tab.
- **FR-010**: After switching workspaces, the app MUST avoid presenting content from the previous workspace as current.
- **FR-011**: The workspace switcher MUST provide an action to add a workspace.
- **FR-012**: Adding a workspace from within the main app MUST use the same connection setup experience presented as a dismissible sheet.
- **FR-013**: Cancelling the add-workspace sheet MUST preserve the previously selected workspace.
- **FR-014**: Completing add-workspace setup MUST save the new workspace and make it available in the switcher.
- **FR-015**: The app MUST provide a user-visible way to log out of the current workspace from the workspace switcher.
- **FR-016**: Logging out of the current workspace MUST remove that workspace from future launches and workspace switching.
- **FR-017**: Logging out of the last saved workspace MUST return the app to first-time connection setup.
- **FR-018**: Connection, switching, add-workspace, and logout failures MUST produce clear recoverable messages.
- **FR-019**: The workspace model MUST distinguish saved workspaces, the current workspace, unavailable workspaces, and no-workspace state.

### Key Entities *(include if feature involves data)*

- **Workspace**: A saved destination the user can open in Agents Mobile, including a user-recognizable name or identity and the information needed to reconnect.
- **Current Workspace Selection**: The workspace the app opens by default and uses to scope tabs, sessions, chat, labels, and resource views.
- **Remote Connection**: The user-entered connection information that allows the app to discover and access one or more workspaces.
- **Workspace Switcher**: The simple global control opened from the top-leading workspace button that lists saved workspaces and exposes switching, adding, and current-workspace logout actions.

### Assumptions

- “Workspace” in the mobile app means a remote Craft Agents workspace or connection destination; desktop local-folder management remains out of scope.
- Saved workspaces require durable local persistence across launches. The exact storage mechanism is a planning decision, while the user-visible requirement is that workspaces survive app restarts reliably.
- The selected workspace may be stored separately from the saved workspace records as long as it restores consistently across launches.
- Adding a workspace does not need to interrupt or discard the currently active workspace unless the user explicitly switches.
- Workspace logout removes local access for the current workspace from this device; it does not delete the workspace from the remote server.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of fresh launches with no saved workspaces show connection setup before any main tab content.
- **SC-002**: 100% of launches with a selected saved workspace open directly into that workspace without requiring repeated setup.
- **SC-003**: Users can identify the current workspace from any main tab without opening another screen.
- **SC-004**: Users can switch between two saved workspaces from any tab in 3 interactions or fewer.
- **SC-005**: Users can add a new workspace from the main app without losing the previously active workspace if they cancel.
- **SC-006**: Logging out of the final saved workspace returns the app to connection setup on the next visible state and on the next launch.
- **SC-007**: In usability review, users can correctly explain which workspace is active and how to switch workspaces in at least 9 out of 10 attempts.
