# Agents Mobile

Native iOS companion app for connecting to the embedded Mobile Companion server in the Craft Agents desktop app.

## Requirements

- Xcode / Swift toolchain compatible with SwiftPM tools version 6.3
- Tuist
- SwiftFormat (`brew install swiftformat`)
- SSH access to `git@github.com:pointfreeco/TCA26.git`

## Setup

From this directory:

```bash
tuist install
tuist generate
swiftformat .
```

Then open the generated workspace/project in Xcode.

## Formatting

From the repo root:

```bash
bun run ios:format
bun run ios:format:check
```

Or from `apps/ios` directly:

```bash
swiftformat .
swiftformat --lint .
```

## Current scope

This is an initial scaffold only:

- SwiftUI app target named `AgentsMobile`
- Unit test target
- Tuist project setup
- Private TCA26 dependency via product `ComposableArchitecture2`

Next steps:

1. Add pairing screen
2. Add WebSocket RPC client
3. Implement handshake against the Craft Agents embedded server
4. Load workspaces with `server:getWorkspaces`
