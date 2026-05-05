# Agents Mobile Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-05-05

## Active Technologies

- Swift tools 6.3
- UIKit app shell and view controllers
- ComposableArchitecture2 for feature state, actions, routing, effects, and tests
- Sharing for lightweight persisted app preferences such as current workspace selection
- SQLiteData and StructuredQueries for durable local workspace records
- Existing Craft companion RPC client in an `RPCClient` module for remote workspace discovery and session loading
- Single Package.swift with small modules following the isowords style: `Database`, `RPCClient`, `ConnectionFeature`, and `AppFeature`
- FlowDeck for Apple platform build, test, launch, and smoke verification

## Project Structure

```text
apps/ios/
├── Package.swift
├── Sources/
│   ├── Database/
│   ├── RPCClient/
│   ├── ConnectionFeature/
│   └── AppFeature/
├── Tests/
│   ├── DatabaseTests/
│   ├── ConnectionFeatureTests/
│   ├── AppFeatureTests/
│   └── RPCClientTests/
├── specs/memory/constitution.md
└── specs/workspace-support/
```

## Commands

```bash
flowdeck build
flowdeck test
swiftformat .
swiftformat --lint .
```

## Code Style

- Keep product state explicit and tightly modeled.
- Prefer small, functionally grouped modules when a real boundary is visible.
- Prefer localized duplication over premature abstraction until a shared shape earns its place.
- Name user actions after what the user did, and effect responses after the data returned.
- Do not use direct Apple CLI tooling for build, test, simulator, device, launch, log, or automation work; use FlowDeck.

## Recent Changes

- workspace-support: Plans a modular package layout with `Database`, `RPCClient`, `ConnectionFeature`, and `AppFeature`, plus persisted workspaces, current workspace selection, a top-leading workspace button, a simple switcher, add-workspace sheet, and current-workspace logout.

<!-- MANUAL ADDITIONS START -->

## Dependency Source Review Policy

When inspecting source files from dependencies, look ONLY at their visible API surface and comments/documentation. Do NOT read or rely on dependency implementation details. Looking at dependency example apps, sample code, README files, and public documentation is highly recommended when learning correct usage patterns.

<!-- MANUAL ADDITIONS END -->
