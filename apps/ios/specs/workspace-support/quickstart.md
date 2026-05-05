# Quickstart: Workspace Support

## Prerequisites

- A Craft Agents desktop app or compatible remote server with at least one workspace available.
- Mobile companion URL and token from the desktop app.
- From `/Users/laksh/Developer/craft-agents-oss/apps/ios`, use FlowDeck for Apple platform build, test, and smoke verification.

## Build and Test

```bash
flowdeck build
flowdeck test
```

If formatting changes are included:

```bash
swiftformat .
swiftformat --lint .
```

## Smoke Path 1: First Workspace Setup

1. Start from a clean install or clear saved workspace data.
2. Launch the app.
3. Verify the connection setup screen appears before any main tab.
4. Enter a valid server URL and token.
5. Complete connection setup.
6. Verify the main app opens and the top-leading workspace button shows the current workspace.

Expected result: first setup saves the workspace, selects it, and opens Sessions scoped to it.

## Smoke Path 2: Return to Current Workspace

1. With one saved workspace selected, terminate the app.
2. Relaunch the app.
3. Verify the app opens directly into the main tabs.
4. Verify the top-leading workspace button shows the selected workspace.

Expected result: the user does not repeat setup and workspace context is visible immediately.

## Smoke Path 3: Add Workspace from Main App

1. Tap the top-leading workspace button.
2. Verify the workspace switcher appears with Add Workspace and Logout Current Workspace actions.
3. Tap Add Workspace.
4. Verify the connection setup flow appears in a dismissible sheet.
5. Cancel the sheet.
6. Verify the original workspace remains current.
7. Repeat Add Workspace and complete setup with a second workspace.
8. Verify the new workspace appears in the switcher.

Expected result: adding is modal and does not destroy the previous workspace context.

## Smoke Path 4: Switch Workspace

1. Save at least two workspaces.
2. Tap the top-leading workspace button.
3. Select a different workspace.
4. Verify the button updates to the selected workspace.
5. Verify Sessions reloads or returns to an appropriate not-loaded/loading state for the selected workspace.
6. Verify previous-workspace session content is not described as current.

Expected result: switching applies globally to the main app shell and tabs.

## Smoke Path 5: Logout Current Workspace

1. Tap the top-leading workspace button.
2. Tap Logout Current Workspace.
3. If multiple workspaces exist, verify the current workspace is removed and another workspace becomes current or the app asks for a choice.
4. If one workspace exists, verify the app returns to first-time connection setup.
5. Relaunch the app and verify the logged-out workspace does not return.

Expected result: logout removes local access for the current workspace only and leaves the app in a valid route.

## Regression Checks

- Pull-to-refresh in Sessions still works after first setup.
- Connection errors remain recoverable.
- Cancelling add-workspace does not alter current workspace selection.
- The workspace button appears consistently on every main tab.
- No token or secret connection detail is visible in labels, logs, or screenshots.
