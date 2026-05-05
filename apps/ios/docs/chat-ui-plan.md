# Agents Mobile Chat Experience Goals

## Purpose

Chat is the primary place where users understand, direct, and resume agent work from mobile. The mobile chat experience should feel fast, clear, trustworthy, and native while preserving the meaning and structure users expect from the desktop app.

This document describes product goals for the chat surface rather than implementation details.

## Product Principles

- **Chat is the center of work.** Most meaningful changes, follow-ups, reviews, and approvals should be reachable from the session conversation.
- **The user should always know what the agent is doing.** In-progress thinking, tool use, waiting states, failures, and completed work should be visible and understandable.
- **Mobile should be optimized for quick intervention.** Users should be able to read progress, reply, approve, deny, or jump back later with minimal friction.
- **Conversation history should feel durable.** Recently opened sessions should be easy to revisit, even when the connection is slow or temporarily unavailable.
- **The experience should match desktop meaning, not desktop layout.** Mobile can use native presentation patterns as long as session structure and context remain familiar.

## Chat Experience Goals

### 1. Clear Conversation Timeline

The chat view should present a readable timeline of user messages, assistant responses, system events, tool activity, permission requests, credential prompts, and errors.

The experience should make it obvious:

- who said or did what
- what the latest agent status is
- whether the agent is still working
- whether user attention is required
- what changed since the user last opened the session

### 2. High-Quality Assistant Turns

Assistant activity should be grouped into meaningful turns rather than shown as an overwhelming stream of raw events.

Each assistant turn should be able to show:

- progress and activity summary
- intermediate updates when useful
- final response content
- tool or automation activity in a compact form
- warnings, errors, or blocked states
- review or approval needs

The goal is to make long-running agent work easy to scan on a phone.

### 3. Live Progress Without Jank

When an agent is actively responding, the UI should update smoothly and remain usable. Streaming text, progress updates, and tool activity should feel alive without causing distracting jumps or making older content hard to read.

The user should be able to scroll away from the bottom without being forced back, and sending a new message should return focus to the latest activity.

### 4. Reliable Send and Resume Flow

Users should be able to continue a session naturally from mobile:

- compose and send a follow-up message
- see that the message is being sent
- understand whether the agent has started working
- recover gracefully from connection failures
- preserve drafts when possible

The chat surface should make failures actionable rather than mysterious.

### 5. Permission and Credential Moments

Permission requests and credential prompts should be first-class chat moments, not hidden alerts. They should clearly explain what the agent needs, why it needs it, and what the user's options are.

Users should be able to approve, deny, provide credentials, or defer these requests from the session context.

### 6. Fast Return to Recent Work

Opening a session should quickly show useful cached context first, then refresh with the latest server state. The user should not wait on a blank screen when recent conversation history is already available.

Older history should be available when needed, but the newest work should remain the fastest path.

### 7. Native Reading Experience

Messages should be comfortable to read on iPhone and iPad. Markdown, links, file references, lists, code snippets, and structured agent output should render clearly enough for mobile review.

The first version can be visually simple, but it should preserve enough information that richer rendering can improve over time.

## MVP Chat Scope

The first complete mobile chat experience should support:

1. Opening a session and reading its conversation history.
2. Seeing current status and in-progress agent work.
3. Sending follow-up messages.
4. Receiving live updates while the session is active.
5. Showing clear loading, empty, offline, reconnecting, and error states.
6. Handling permission and credential prompts in context.
7. Keeping scroll behavior predictable during live updates.
8. Preserving drafts and recent conversation context where possible.

## What to Avoid

The chat experience should avoid:

- exposing raw implementation events to users
- making tool activity dominate the conversation
- forcing users back to the bottom while they are reading older messages
- hiding permission or failure states outside the session context
- building a chat screen that cannot later support notifications, Live Activities, or background refresh
- copying desktop layout too literally when a native mobile pattern would be clearer

## Success Criteria

The chat surface is successful when users can:

- quickly understand what happened in a session
- continue an agent conversation from mobile with confidence
- monitor active work without keeping desktop open
- respond to approvals or failures at the right moment
- return to recent work without losing context

A visually simple first version is acceptable if these product behaviors are solid.
