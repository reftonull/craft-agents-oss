# Agents Mobile Foundations Goals

## Purpose

Before expanding into deeper product surfaces, Agents Mobile needs a stable foundation that supports reliable browsing, chat, workspace switching, live updates, and future mobile-specific features.

This document describes product-level foundation goals rather than low-level implementation details.

## Foundation Goal

The app should feel like a dependable companion even when work is long-running, the network changes, or the user moves between sessions and workspaces.

Foundational work should make it possible for users to:

- open the app and quickly see recent workspace activity
- trust that session lists and chat history are current enough to act on
- continue work without losing drafts or context
- understand connection and sync state
- switch workspaces without confusing stale data
- respond to live agent activity, approvals, and failures
- return later and resume where they left off

## Guiding Principles

- **The desktop or hosted server remains the source of truth.** Mobile presents and continues server-owned work.
- **Mobile should be resilient.** Recent data should be available quickly, even when reconnecting.
- **Workspace context should be explicit.** Users should always know what workspace they are viewing.
- **Sessions and chat should share one consistent data path.** The same information should power lists, details, notifications, and future mobile surfaces.
- **User intent should be preserved.** Drafts, selected workspace, recent sessions, and pending actions should survive normal app interruptions.
- **Complex changes should be agent-driven where appropriate.** The foundation should support contextual agent conversations for configuration and organization tasks.

## Core Foundation Areas

### 1. Workspace and Connection Experience

Users should be able to connect to a workspace, see connection status, recover from failures, and switch workspaces confidently.

Product goals:

- show the active workspace clearly
- make pairing, logout, and reconnect states understandable
- support a future where users may have more than one saved connection
- avoid exposing desktop-only local workspace concepts
- keep workspace switching predictable and safe

### 2. Fast, Reliable Session Browsing

The sessions list should be useful immediately and then refresh as newer information arrives.

Product goals:

- show recent cached sessions quickly when available
- refresh from the server without disrupting browsing
- communicate loading, stale, offline, and error states clearly
- keep status, unread, flagged, archived, and in-progress indicators accurate enough for decision-making
- support search and common filters as the session list grows

### 3. Durable Chat Context

Chat should not feel temporary or fragile. Users should be able to reopen recent conversations, see context, and continue work without waiting for everything to reload from scratch.

Product goals:

- preserve recent conversation history for quick return
- keep drafts when users leave and come back
- recover gracefully after app termination or network loss
- support live updates while a session is open
- make send failures and retry paths clear

See [Agents Mobile Chat Experience Goals](./chat-ui-plan.md) for the chat-specific experience goals.

### 4. Live Agent Awareness

The foundation should support timely updates about active agent work.

Product goals:

- reflect when an agent is running, blocked, failed, or complete
- update open sessions as work progresses
- keep session rows aligned with current work status
- support permission and credential requests as actionable moments
- prepare for notifications, Live Activities, and background refresh later

### 5. Workspace Switching Behavior

Switching workspaces should feel intentional and clean, not like every screen is independently guessing what changed.

Product goals:

- load the selected workspace's recent data quickly
- avoid showing stale sessions from the previous workspace as current
- reset or preserve navigation in a way that matches user expectations
- make unavailable or expired workspaces easy to recover from
- keep labels, resources, and filters scoped to the active workspace

### 6. Shared Mobile Domain Language

The app should present consistent concepts across screens: workspace, session, message, label, source, skill, automation, permission request, credential request, and agent status.

Product goals:

- use the same names and meanings across the app
- avoid exposing server internals in the UI
- make missing or partially supported data degrade gracefully
- allow richer presentation to be added later without changing product meaning

### 7. Agent-Driven Action Foundation

Because the mobile app should not need full native editors for every configuration task, it needs a reusable way to start contextual agent work.

Product goals:

- let users ask an agent to create, edit, configure, organize, or troubleshoot
- carry enough context into the conversation that the user does not need to restate everything
- make the resulting work trackable and recoverable
- avoid cluttering the main session list with system-like management work unless the user needs to see it

Examples include:

- add or configure a source
- edit a skill
- create an automation
- organize selected sessions
- create or adjust labels
- troubleshoot workspace setup

### 8. Testing and Confidence

The foundation should be tested around user-visible behavior, especially where mobile interruptions and live updates can create confusing states.

Product goals:

- pairing and reconnect flows are reliable
- sessions appear correctly after launch, refresh, logout, and workspace switch
- chat history and drafts survive common interruptions
- live updates do not duplicate, lose, or misorder important user-visible events
- failures produce clear recovery paths

## Suggested Product Milestones

### Milestone 1: Reliable Workspace Home

- connect to a workspace
- show the active workspace and connection state
- load recent sessions quickly
- refresh sessions reliably
- handle logout, reconnect, and failure states clearly

### Milestone 2: Durable Session Detail

- open a session from the list
- show recent conversation history
- preserve enough context to return quickly
- display status, progress, and errors clearly

### Milestone 3: Continue Work from Mobile

- send follow-up messages
- preserve drafts
- show sending, working, failed, and completed states
- support live progress while a session is open

### Milestone 4: Workspace and Organization Expansion

- support workspace switching where available
- show labels and common filters
- keep organization metadata aligned with sessions

### Milestone 5: Resource Awareness and Agent Actions

- inspect sources, skills, and automations
- start contextual agent conversations for changes
- track agent-driven management work without clutter

## What to Avoid

Foundational work should avoid:

- building screens that each manage server data differently
- making chat depend on fragile one-off loading behavior
- treating workspace switching as an afterthought
- losing drafts or context during normal app lifecycle changes
- exposing raw protocol or storage concepts to users
- over-investing in advanced offline editing before reliable online continuation works

## Success Criteria

The foundation is ready for deeper product work when:

- users can launch the app and quickly understand current workspace activity
- session lists and details remain coherent through reconnects and refreshes
- chat can support live work without losing history or drafts
- workspace switching has predictable behavior
- common failure states are visible and recoverable
- future features such as notifications, Live Activities, and background refresh can build on the same product model
