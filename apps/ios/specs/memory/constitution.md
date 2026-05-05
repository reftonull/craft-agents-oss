<!--
Sync Impact Report
Version change: 1.0.0 -> 1.0.0
Modified principles:
- V. Verified Apple Platform Delivery -> V. Strive for Tight Domain Modeling
Added principles:
- VI. Prefer Duplication Over Premature Abstraction
- VII. Testing in Some Form
Added sections: None
Removed sections:
- Engineering Core Principles; folded into core principles V and VI
Templates requiring updates:
- /Users/laksh/.pi/agent/skills/speckit-plan/templates/plan-template.md - reviewed; no edit needed because Constitution Check is already generic and resolved from this file during planning
- /Users/laksh/.pi/agent/skills/speckit-specify/templates/spec-template.md - reviewed; no edit needed because required user scenarios, requirements, and success criteria already support these principles
- /Users/laksh/.pi/agent/skills/speckit-tasks/templates/tasks-template.md - reviewed; no edit needed because user-story phases, tests, polish, and validation checkpoints already support these principles
- apps/ios/README.md - updated with revised v1 principle summary
Follow-up TODOs: None
-->
# Agents Mobile Constitution

## Core Principles

### I. Companion Client, Not Replacement Server
Agents Mobile MUST remain a native companion for Craft Agents work owned by the desktop or
hosted server. The app MUST NOT implement a second backend, duplicate server-side workspace
management, or expose desktop local-folder concepts as mobile product concepts. Every feature
MUST preserve the model that mobile connects to and continues server-owned workspace work.

Rationale: A companion model keeps mobile focused, avoids conflicting sources of truth, and
lets the desktop or hosted server remain responsible for execution, persistence, and workspace
ownership.

### II. Sessions and Chat Are the Core Product
Sessions and chat MUST be treated as the primary mobile experience. Features that affect
session browsing, session detail, chat, progress visibility, approvals, credentials, failures,
or follow-up messages MUST protect clarity, speed, and continuity for those flows. New surfaces
MUST NOT take priority over making session monitoring and conversation continuation reliable.

Rationale: The mobile app creates the most value when users can understand what is happening,
respond when needed, and continue agent work away from the desktop.

### III. Resilient Workspace Context
The active workspace, connection state, and freshness of visible data MUST be clear to users.
Workspace switching MUST avoid presenting stale sessions, labels, resources, or chat content as
current. Recent sessions, recent chat context, drafts, and pending user intent MUST be preserved
across normal app interruptions whenever doing so is safe and understandable.

Rationale: Mobile users frequently move through unstable network and app lifecycle states; the
app must remain trustworthy when reconnecting, switching context, or resuming work.

### IV. Native UI for Bounded Actions, Agent-Driven for Complex Work
Frequent, deterministic, reversible, and bounded actions MUST use native mobile UI. Open-ended,
rare, schema-like, or explanatory changes MUST be offered through contextual agent
conversations. Product proposals MUST classify each write path using this rule before adding a
new screen or control.

Rationale: This split keeps the mobile interface small and fast while preserving access to
powerful configuration, organization, and troubleshooting workflows.

### V. Strive for Tight Domain Modeling
Important product states MUST be modeled with focused, explicit domain types. Workspace
identity, session status, chat progress, permission requests, credential prompts, connection
state, drafts, and agent-driven actions MUST avoid loose collections of unrelated flags when a
clearer model can make invalid states unrepresentable. Small, functionally grouped modules are
preferred when a product or engineering boundary is visible.

Rationale: Tight models and cohesive modules make mobile behavior easier to reason about,
review, test, and evolve without losing product meaning.

### VI. Prefer Duplication Over Premature Abstraction
Localized duplication is preferred over abstraction until the right abstraction presents itself.
Code MUST NOT introduce generic layers, protocols, wrappers, modules, or type systems that do
not remove a real invalid state, clarify a real boundary, improve testability, or simplify a
repeated product concept. When tight modeling and abstraction pressure conflict, the concrete
model that best represents the current product behavior wins until repetition proves otherwise.

Rationale: The wrong abstraction hides product detail and slows change; deliberate duplication
keeps intent visible until a useful pattern has earned a shared shape.

### VII. Testing in Some Form
Every behavior-changing or user-visible change MUST include testing in some form. Acceptable
verification includes automated unit, reducer, integration, or snapshot tests; agentic smoke
tests through FlowDeck; or documented manual verification when automation is not yet practical.
The verification path MUST be recorded in the plan, task notes, or review summary. Docs-only
changes MUST be reviewed for accuracy against the product and workflow they describe.

Rationale: The project needs confidence for every change without forcing every small increment
into the same testing shape.

## Product Constraints

Agents Mobile MUST present Craft Agents concepts in mobile-appropriate language while
preserving desktop meaning for workspaces, sessions, messages, labels, sources, skills,
automations, permission requests, credential requests, and agent status. The app MUST make
loading, empty, offline, reconnecting, stale, failed, blocked, and completed states visible in
user-facing flows where those states affect decisions.

Secrets, tokens, credentials, and private workspace content MUST NOT be exposed in logs,
screenshots, documentation examples, or generated fixtures unless explicitly sanitized. New
mobile-specific features such as notifications, Live Activities, widgets, Share Sheet, camera,
voice, and shortcuts MUST amplify awareness, intervention, or context capture; they MUST NOT
bypass the session and workspace model.

## Development Workflow

Feature work MUST begin from user-visible scenarios and measurable success criteria. Plans MUST
include a Constitution Check that explains how the feature satisfies the core principles or
records justified violations before implementation begins. Tasks MUST be organized into
independently testable user-story slices, with foundational work separated from story delivery.

Every implementation change MUST include one appropriate verification path before completion:
passing relevant automated tests, an agentic FlowDeck smoke test, documented manual
verification, or an explicit reason why only documentation review applies. Documentation MUST be
updated when product behavior, workspace semantics, session/chat behavior, or development
workflow changes.

## Governance

This constitution supersedes conflicting practices for work under `apps/ios`. Amendments MUST
be proposed as a documented change to this file, include a Sync Impact Report, and identify any
required updates to specs, plans, task templates, README guidance, or product documentation.

Versioning follows semantic versioning after v1 ratification:

- MAJOR increments for incompatible governance changes, removed principles, or redefined
  product direction.
- MINOR increments for new principles, new governed sections, or materially expanded guidance.
- PATCH increments for clarifications, wording fixes, or non-semantic refinements.

Compliance review is required during planning and before completion of each feature. Reviewers
MUST verify that the feature preserves the companion model, prioritizes sessions and chat when
relevant, handles workspace context clearly, chooses native or agent-driven actions according to
Principle IV, models important domain states tightly, avoids premature abstraction, and includes
testing in some appropriate form.

**Version**: 1.0.0 | **Ratified**: 2026-05-05 | **Last Amended**: 2026-05-05
