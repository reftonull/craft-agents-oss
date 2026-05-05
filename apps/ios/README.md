# Agents Mobile

Agents Mobile is a native UIKit companion app for Craft Agents on iPhone, iPad, and Mac Catalyst.

It is designed to connect to the existing Craft Agents desktop app rather than replace it. The desktop app continues to own the embedded companion server, session state, tool execution, and workspace management. The mobile app is a focused client for picking up those sessions from Apple devices.

## Vision

The goal is a fast, native companion experience for existing Craft Agents work:

- pair a phone, iPad, or Mac with a running desktop app
- open directly into your paired workspace
- browse and monitor sessions with native loading, refresh, and error feedback
- eventually follow live session updates and continue conversations from mobile

This app is intentionally not a second server implementation. It is a native front end over the desktop app's embedded RPC server.

## Current status

Today the app includes:

- a native **UIKit** app lifecycle (`AppDelegate`, `SceneDelegate`, `UIWindow`)
- **TCA 2** features and routing using `ComposableArchitecture2`
- a checked-in **Xcode project**, local **Swift package**, and **FlowDeck** build/test workflows
- **Mac Catalyst** support alongside iPhone/iPad
- persisted pairing using Point-Free `@Shared`
- a manual pairing flow using server URL, token, and optional workspace ID
- a native Swift WebSocket/RPC client for the Craft companion protocol
- root routing between:
  - onboarding / pairing
  - the main app shell
- a first main screen for **Sessions** with:
  - automatic fetch on entry
  - pull-to-refresh
  - first-load failure handling
  - refresh failure while keeping existing rows visible
  - re-pair support
  - mobile-adapted session row presentation based on the desktop app

Current limitations:

- the Sessions screen is **fetch-only** for now
- session rows are not selectable yet
- no mobile chat/session detail screen yet
- no live `session:event` subscription handling yet

## Architecture

### Desktop remains the source of truth

Agents Mobile connects to the Craft Agents desktop app's embedded server over WebSocket RPC. The mobile app does not start or manage its own backend.

Current RPC usage includes:

- `server:getWorkspaces`
- `sessions:get`
- `session:event` (planned next for live updates)

### Native app structure

The app currently follows this shape:

- **AppFeature**
  - routes to onboarding when no pairing exists
  - routes directly to the main app when pairing is already persisted
- **ConnectionFeature**
  - validates URL/token input
  - connects to the server
  - discovers/selects a workspace
  - verifies the workspace by fetching sessions
- **TabFeature**
  - currently keeps a one-tab shell for future expansion
- **SessionsFeature**
  - owns session loading, refresh, failure states, and re-pair delegation

## Development requirements

Development in this app is governed by the [Agents Mobile Constitution](./specs/memory/constitution.md).
Feature plans and reviews must preserve the companion-client model, prioritize sessions/chat,
keep workspace context clear, model important states tightly, prefer duplication over premature
abstraction, choose native UI versus agent-driven work deliberately, and include testing in some
form, such as automated tests or FlowDeck smoke tests.

- Xcode / Swift toolchain compatible with Swift tools `6.3`
- XcodeGen (`brew install xcodegen`) when regenerating `AgentsMobile.xcodeproj` from `project.yml`
- FlowDeck
- SwiftFormat (`brew install swiftformat`)
- SSH access to `git@github.com:pointfreeco/TCA26.git`

The project currently targets:

- iOS 26.0
- Mac Catalyst

## Setup

From `apps/ios`, resolve Swift packages through Xcode/FlowDeck by building once:

```bash
flowdeck build
```

If you change `project.yml`, regenerate the checked-in project with:

```bash
xcodegen generate
```

## Common commands

From `apps/ios`:

```bash
flowdeck build
flowdeck test
swiftformat .
swiftformat --lint .
```

From the repo root:

```bash
bun run ios:format
bun run ios:format:check
```

## Near-term roadmap

- verify the Sessions screen more thoroughly against a live desktop server
- add live session updates over `session:event`
- open a first session detail / chat experience
- improve row polish and status presentation
- harden persisted pairing/token storage for production use

## Notes

This README describes the current companion app direction in this fork. For the broader repository context and the desktop app, see the top-level [README](../../README.md).
