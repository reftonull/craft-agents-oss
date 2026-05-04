# RPC Client Refactor Plan

## Context

The current Swift RPC client works for the basic mobile companion flow, but its shape is too complex:

- One `LiveRPCClient` actor owns replaceable socket state.
- Server-scope and workspace-scope connections reuse the same actor.
- A previous socket can finish/fail after a newer socket is installed.
- This caused the observed bug:
  - first connect discovers workspace ID,
  - workspace reconnect starts,
  - old socket failure clears/fails new socket,
  - second connect works because old socket has settled.

Diagnostic logs confirmed this:

```txt
connection #1 failed current=#2 error=Socket is not connected
failConnection current=#2 error=Socket is not connected
connection #2 cancelled current=#nil
```

## References

### Craft TypeScript client

`packages/server-core/src/transport/client.ts`

Useful pattern:

```ts
ws.onmessage = event => {
  if (this.ws !== ws) return // stale socket — ignore
}
```

The TypeScript client is a reconnecting socket manager, but it carefully ignores stale socket callbacks.

### SourceKit-LSP / swift-tools-protocols

Looked at:

- `LanguageServerProtocolTransport/JSONRPCConnection.swift`
- `LanguageServerProtocolTransport/LocalConnection.swift`

Useful pattern:

- A `JSONRPCConnection` represents one connection lifetime.
- It owns transport, state, and outstanding requests.
- It serializes mutable state on one queue.
- On close, it fails only its own outstanding requests.

Swift equivalent for us should be one actor per socket connection.

## Proposed design

Split the current type into two concepts.

### `RPCClient`

A dependency/factory only.

```swift
struct RPCClient: Sendable {
  var connect: @Sendable (RPCConnectionRequest) async throws -> RPCConnection
}
```

No global socket. No global disconnect. No replaceable connection state.

### `RPCConnection`

One socket/session lifetime.

```swift
actor RPCConnection {
  func invokeJSON(channel: String, args: [JSONValue]) async throws -> JSONValue
  func invoke<T: Decodable>(_ type: T.Type, channel: String, args: [JSONValue]) async throws -> T
  func events() -> AsyncThrowingStream<RPCConnectionEvent, any Error>
  func close() async
}
```

It owns:

- exactly one `RPCWebSocket`
- handshake result
- `registeredChannels`
- `pendingResponses`
- `lastSeenSequence`
- receive loop for that socket
- event stream continuation

It never replaces its socket.

## Desired feature flow

```swift
let server = try await rpcClient.connect(
  RPCConnectionRequest(url: url, token: token)
)
defer { await server.close() }

let workspaces: [RemoteWorkspace] = try await server.invoke(
  [RemoteWorkspace].self,
  channel: RPCChannel.serverGetWorkspaces
)

let workspace = try await rpcClient.connect(
  RPCConnectionRequest(url: url, token: token, workspaceID: selectedWorkspaceID)
)
defer { await workspace.close() }

let sessions: [RemoteSession] = try await workspace.invoke(
  [RemoteSession].self,
  channel: RPCChannel.sessionsGet
)

for try await event in workspace.events() {
  try store.send(.connectionEvent(event))
}
```

## Invariants

- A connection object owns exactly one socket.
- A closed/failed connection cannot affect another connection.
- Pending requests belong to a single connection.
- Closing a connection fails only that connection's pending requests.
- Workspace switching creates a new connection instead of mutating an existing one.
- No connection IDs/stale guards should be necessary in normal code.

## Dependency policy

Use Point-Free Dependencies for controllable runtime values:

```swift
@Dependency(\.continuousClock) var clock
@Dependency(\.uuid) var uuid
```

Use `clock` for connection/request timeouts, not `Task.sleep`. Use `uuid().uuidString` for wire request IDs, not ad-hoc closures or direct `UUID()` calls.

Tests should override these dependencies:

```swift
withDependencies {
  $0.continuousClock = TestClock()
  $0.uuid = .incrementing
} operation: {
  LiveRPCClient(...)
}
```

Timeouts can remain operation-scoped via structured concurrency, but should be owned by the individual `RPCConnection` operation.

## Test plan

Keep existing Swift Testing coverage and adapt it to the new connection object:

- handshake sends correct envelope
- handshake ack returns `RPCConnectionInfo`
- `invoke` sends request envelope
- response resolves matching pending request
- response error throws `RPCClientError.serverError`
- unavailable channel throws before sending
- request timeout uses injected clock
- event stream emits server push events
- sequence event sends `sequence_ack`
- closing connection fails pending requests
- server connection closing late does not affect workspace connection

## Migration steps

1. Introduce `RPCConnection` actor backed by one `RPCWebSocket`.
2. Change `RPCClient` dependency into a connection factory.
3. Move handshake/start logic into factory or `RPCConnection.start()`.
4. Update `ConnectionFeature` to hold lifecycle in its `store.addTask` flow using local connection values.
5. Delete global `disconnect`/replaceable socket state from `LiveRPCClient`.
6. Delete temporary diagnostic connection IDs/logging.
7. Re-run FlowDeck build/tests and manually verify first connect works without needing a second tap.
