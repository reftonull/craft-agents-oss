# Workspace UI Contract

## Purpose

Defines the user-visible contract for workspace setup, display, switching, adding, and logout.
This is a UI/state contract for the mobile app, not an external API contract.

## Global Workspace Button

### Availability

- Visible in the top-leading area of the shared main app shell whenever main tabs are visible.
- Not visible during first-time setup when no workspace exists.

### Content

- Shows the current workspace display name or a recognizable fallback identity.
- Indicates that it is interactive.
- Does not show tokens, secret connection details, or raw technical metadata.

### Interaction

- Tapping opens the workspace switcher.
- The button reflects workspace changes after switching or fallback selection.

## Workspace Switcher

### Required Content

- Current workspace identity.
- List of saved workspaces.
- Clear indication of the current workspace.
- Add Workspace action.
- Logout Current Workspace action.

### Required Behavior

- Selecting a different workspace changes the current workspace for the whole app.
- Selecting the already-current workspace leaves state unchanged and dismisses or keeps the switcher in a clearly stable state.
- Add Workspace opens the connection setup flow in a dismissible sheet.
- Logout Current Workspace removes local access for the current workspace only.

### Error States

- If switching fails, the switcher or app shell shows a recoverable message and does not present the target workspace as current.
- If logout fails locally, the app keeps the workspace visible and shows a recoverable message.

## Add Workspace Sheet

### Presentation

- Presented from the workspace switcher as a dismissible sheet.
- Reuses the same connection setup experience as first-time setup.

### Cancellation

- Cancelling dismisses the sheet.
- The previous current workspace remains selected.
- No partial workspace is shown in the switcher.

### Success

- The new workspace is saved locally.
- The new workspace appears in the switcher.
- The user can switch to it immediately.
- Duplicate saved workspaces are not added as separate entries.

## First-Time Setup

### Presentation

- Shown as the root experience when no saved workspace exists.
- Not dismissible into an empty main app.

### Success

- Saves the workspace locally.
- Sets it as current.
- Opens the main app scoped to the new workspace.

### Failure

- Keeps the user in setup.
- Shows a clear recoverable error.

## Logout Current Workspace

### Single Workspace

- Removes local access to the current workspace.
- Clears current selection.
- Routes to first-time setup.

### Multiple Workspaces

- Removes local access to the current workspace.
- Selects a safe fallback workspace or asks the user to choose one.
- Re-scopes all tabs to the resulting current workspace.

## Non-Goals

- Remote deletion of a workspace.
- Full workspace administration.
- Editing workspace names or server details after saving.
- Logging out arbitrary non-current workspaces in the first slice.
