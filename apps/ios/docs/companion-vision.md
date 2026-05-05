# Agents Mobile Companion Vision

## Summary

Agents Mobile should be a native companion for Craft Agents: a focused way to monitor, understand, and continue agent work while away from the desktop.

The mobile app does not need to recreate every desktop management screen. Its highest-value role is to make workspaces, sessions, chat, labels, and agent-supporting resources easy to browse and act on from a phone. When a task is complex or open-ended, the app should start an agent conversation instead of forcing users through dense configuration UI.

## Product North Star

Agents Mobile should help users answer three questions quickly:

1. **What is happening?** See active, completed, failed, unread, and review-needed work.
2. **What needs me?** Respond to messages, approvals, credentials, and failures.
3. **What can I do next?** Continue a session, start a new request, organize work, or ask an agent to make a change.

## MVP Goal

For MVP, Agents Mobile should support the daily companion loop:

- connect to a Craft Agents workspace
- browse and switch workspaces where available
- browse, search, filter, and open sessions
- read and continue agent conversations with a strong mobile chat experience
- understand session status, progress, labels, and review needs
- inspect sources, skills, and automations at a high level
- start agent-driven actions for changes that do not need dedicated mobile UI

The MVP should prioritize depth and reliability in sessions and chat over breadth in settings and configuration.

## Core Product Areas

### Workspaces

Workspaces are the top-level context for mobile work. Users should be able to see which workspace they are in, switch when needed, and understand connection status clearly.

On mobile, workspaces should feel like remote destinations. The app should not expose desktop local-folder management concepts. Whether the server is hosted remotely or running on the user's Mac, the mobile experience should present it as a connected workspace.

Product goals:

- make the active workspace obvious
- support switching without confusion
- preserve user context when possible
- handle disconnected, expired, or unavailable workspaces gracefully

### Sessions

Sessions are the main unit of agent work and should be the app's primary browsing surface.

Product goals:

- show recent and important sessions quickly
- make active, failed, unread, flagged, archived, and review-needed states easy to recognize
- support search and common filters
- make labels and status useful for navigation
- open directly into a clear chat/detail experience

### Chat

Chat is the deepest and most important surface. It is where users understand agent work, continue conversations, respond to approvals, and recover from problems.

Product goals:

- present conversation history clearly
- show live progress and current agent status
- support sending follow-up messages
- make permission and credential requests actionable
- keep long sessions readable on mobile
- preserve context when returning to recent work

See [Agents Mobile Chat Experience Goals](./chat-ui-plan.md) for the chat-specific product goals.

### Labels

Labels help users organize and revisit sessions.

For MVP, labels should primarily support browsing and filtering. Basic assignment may be useful if it is frequent and simple, while complex label management can be handled through agent-driven actions.

Product goals:

- show labels on sessions
- filter sessions by label
- browse label-focused session lists
- make common organization tasks easy

### Sources, Skills, and Automations

Sources, skills, and automations explain what agents can access and do. Mobile users should be able to inspect them enough to understand capabilities and troubleshoot issues.

For MVP, these areas can be mostly read-only with clear actions to ask an agent to add, update, configure, or fix them.

Product goals:

- list available resources
- explain what each item is for
- surface health or configuration issues when known
- provide agent-driven entry points for changes

## Native UI vs Agent-Driven Work

Agents Mobile should use native UI for frequent, bounded actions and agent conversations for open-ended changes.

### Should Be Native UI

- pairing and connection status
- workspace switching
- sessions list and session detail
- chat and message composition
- status and permission mode controls
- permission approvals and credential prompts
- basic labels, search, filters, and sorting
- common review and follow-up actions

### Can Be Agent-Driven

- creating or restructuring labels
- configuring sources
- editing skills
- creating automations
- building advanced saved views
- troubleshooting setup problems
- rare or complex settings changes

The product rule is:

> If the action is frequent, simple, reversible, and easy to explain visually, make it native. If the action is complex, rare, or benefits from guided explanation, make it agent-driven.

## Agent-Driven Actions

Instead of building a custom mobile screen for every configuration task, the app can offer intent-oriented actions such as:

- “Create label”
- “Organize these sessions”
- “Add a source”
- “Configure this skill”
- “Create an automation”
- “Troubleshoot this workspace”

Tapping one should open a contextual agent conversation with the relevant workspace or object already in mind. This keeps the mobile UI focused while still giving users access to powerful changes.

## MVP Experience Sequence

A practical MVP path is:

1. **Reliable sessions home**
   - browse, search, filter, refresh, and understand status

2. **Session detail and chat**
   - read history, continue conversations, and see live progress

3. **Workspace awareness**
   - show active workspace and support switching where available

4. **Labels and organization**
   - display labels and support common label-based browsing

5. **Resource inspection**
   - view sources, skills, and automations at a high level

6. **Agent-driven actions**
   - launch contextual conversations for configuration and organization tasks

## Mobile-Specific Opportunities

After the core companion loop is reliable, mobile should lean into things desktop cannot do as naturally:

- Live Activities for long-running agent work
- push notifications for completed work, failures, approvals, and handoffs
- quick approval flows from notifications
- widgets for active or review-needed sessions
- Share Sheet capture for text, URLs, files, images, and screenshots
- camera and photo workflows for real-world context
- voice-first prompts and dictation
- Siri, App Intents, and Shortcuts
- background refresh for recent sessions and badges
- handoff and deep links between desktop and mobile
- offline-friendly reading for recent work

These features should amplify awareness and quick intervention: know what is happening, respond when needed, and capture useful context from anywhere.

## What to Avoid

Agents Mobile should avoid:

- duplicating every desktop settings screen
- exposing desktop local-folder concepts
- making users manage technical connection details unnecessarily
- building separate mobile-only behavior that conflicts with desktop meaning
- prioritizing broad configuration UI before sessions and chat are excellent
- turning agent-driven workflows into hidden magic without clear user feedback

## Related Docs

- [Agents Mobile Foundations Goals](./foundations-plan.md)
- [Agents Mobile Chat Experience Goals](./chat-ui-plan.md)

## Open Product Questions

- How many connected workspaces or remotes should MVP expose?
- Which filters are essential on mobile from day one?
- Which agent-driven actions should appear first?
- Should hidden management sessions be visible in a special activity area?
- Which repeated agent-driven actions should eventually become native controls?
