import ComposableArchitecture2
import Foundation
@testable import RPCClient
import Testing

@Suite("LiveRPCClient")
struct LiveRPCClientTests {
  @Test
  func `connect sends handshake and publishes connected event`() async throws {
    let socket = TestRPCWebSocket()
    let client = makeClient(webSocketFactory: .mock(socket))

    let connectionTask = Task {
      try await client.connect(
        RPCConnectionRequest(
          url: #require(URL(string: "ws://desktop.local:9100")),
          token: "secret-token",
          workspaceID: "workspace-1"
        )
      )
    }

    let sentHandshake = try await RPCEnvelope.decode(socket.nextSentMessage())
    #expect(sentHandshake == RPCEnvelope(
      id: UUID(0).uuidString,
      type: .handshake,
      protocolVersion: RPCProtocol.version,
      token: "secret-token",
      workspaceId: "workspace-1"
    ))

    let handshakeAcknowledgement = try RPCEnvelope(
      id: UUID(0).uuidString,
      type: .handshakeAck,
      clientId: "client-1",
      protocolVersion: "1.0",
      registeredChannels: [RPCChannel.serverGetWorkspaces, RPCChannel.sessionsGet],
      serverVersion: "0.1.0"
    ).encodedString()
    await socket.serverSend(handshakeAcknowledgement)

    let connection = try await connectionTask.value
    var iterator = await (connection.events()).makeAsyncIterator()

    #expect(try await iterator.next() == .connecting)
    #expect(try await iterator.next() == .handshaking)
    #expect(try await iterator.next() == .connected(RPCConnectionInfo(
      clientID: "client-1",
      protocolVersion: "1.0",
      registeredChannels: [RPCChannel.serverGetWorkspaces, RPCChannel.sessionsGet],
      reconnected: false,
      serverVersion: "0.1.0",
      stale: false
    )))

    await connection.close()
  }

  @Test
  func `invoke sends request and decodes response`() async throws {
    struct Workspace: Decodable, Equatable {
      var id: String
      var name: String
      var slug: String
    }

    let socket = TestRPCWebSocket()
    let client = makeClient(webSocketFactory: .mock(socket))

    let connection = try await connect(
      client,
      socket: socket,
      registeredChannels: [RPCChannel.serverGetWorkspaces]
    )

    let workspaces = Task {
      try await connection.invoke(
        [Workspace].self,
        channel: RPCChannel.serverGetWorkspaces
      )
    }

    let request = try await RPCEnvelope.decode(socket.nextSentMessage())
    #expect(request == RPCEnvelope(
      id: UUID(1).uuidString,
      type: .request,
      args: [],
      channel: RPCChannel.serverGetWorkspaces
    ))

    let response = try RPCEnvelope(
      id: UUID(1).uuidString,
      type: .response,
      channel: RPCChannel.serverGetWorkspaces,
      result: .array([
        .object([
          "id": .string("workspace-1"),
          "name": .string("Personal"),
          "slug": .string("personal"),
        ]),
      ])
    ).encodedString()
    await socket.serverSend(response)

    #expect(try await workspaces.value == [Workspace(id: "workspace-1", name: "Personal", slug: "personal")])

    await connection.close()
  }

  @Test
  func `rejects unavailable channels advertised by the server`() async throws {
    let socket = TestRPCWebSocket()
    let client = makeClient(webSocketFactory: .mock(socket))

    let connection = try await connect(
      client,
      socket: socket,
      registeredChannels: [RPCChannel.serverGetWorkspaces]
    )

    await #expect(throws: RPCClientError.channelUnavailable(RPCChannel.sessionsGet)) {
      try await connection.invokeJSON(channel: RPCChannel.sessionsGet)
    }

    await connection.close()
  }

  @Test
  func `propagates response errors`() async throws {
    let socket = TestRPCWebSocket()
    let client = makeClient(webSocketFactory: .mock(socket))

    let connection = try await connect(
      client,
      socket: socket,
      registeredChannels: [RPCChannel.serverGetWorkspaces]
    )

    let result = Task { try await connection.invokeJSON(channel: RPCChannel.serverGetWorkspaces) }
    _ = try await socket.nextSentMessage()

    let error = RPCWireError(code: "HANDLER_ERROR", message: "Boom")
    let response = try RPCEnvelope(
      id: UUID(1).uuidString,
      type: .response,
      channel: RPCChannel.serverGetWorkspaces,
      error: error
    ).encodedString()
    await socket.serverSend(response)

    await #expect(throws: RPCClientError.serverError(error)) {
      try await result.value
    }

    await connection.close()
  }

  @Test
  func `times out requests that never receive a response`() async throws {
    let socket = TestRPCWebSocket()
    let clock = TestClock()
    let client = makeClient(
      configuration: RPCClientConfiguration(requestTimeout: .seconds(1)),
      webSocketFactory: .mock(socket),
      clock: clock
    )

    let connection = try await connect(
      client,
      socket: socket,
      registeredChannels: [RPCChannel.serverGetWorkspaces]
    )

    let result = Task { try await connection.invokeJSON(channel: RPCChannel.serverGetWorkspaces) }
    _ = try await socket.nextSentMessage()

    await clock.advance(by: .seconds(1))

    await #expect(throws: RPCClientError.requestTimedOut(channel: RPCChannel.serverGetWorkspaces)) {
      try await result.value
    }

    await connection.close()
  }

  @Test
  func `closing connection fails pending requests`() async throws {
    let socket = TestRPCWebSocket()
    let client = makeClient(webSocketFactory: .mock(socket))

    let connection = try await connect(
      client,
      socket: socket,
      registeredChannels: [RPCChannel.serverGetWorkspaces]
    )

    let result = Task { try await connection.invokeJSON(channel: RPCChannel.serverGetWorkspaces) }
    _ = try await socket.nextSentMessage()

    await connection.close()

    await #expect(throws: RPCClientError.disconnected) {
      try await result.value
    }
  }

  @Test
  func `fails connection when handshake acknowledgement never arrives`() async throws {
    let socket = TestRPCWebSocket()
    let clock = TestClock()
    let client = makeClient(
      configuration: RPCClientConfiguration(connectTimeout: .seconds(1)),
      webSocketFactory: .mock(socket),
      clock: clock
    )

    let connectionTask = Task {
      try await client.connect(
        RPCConnectionRequest(
          url: #require(URL(string: "ws://desktop.local:9100")),
          token: "secret-token"
        )
      )
    }
    _ = try await socket.nextSentMessage()

    await clock.advance(by: .seconds(1))

    await #expect(throws: RPCClientError.connectTimedOut) {
      try await connectionTask.value
    }
  }

  @Test
  func `acknowledges the latest event sequence`() async throws {
    let socket = TestRPCWebSocket()
    let client = makeClient(webSocketFactory: .mock(socket))

    let connection = try await connect(
      client,
      socket: socket,
      registeredChannels: [RPCChannel.sessionsGet]
    )
    var iterator = await (connection.events()).makeAsyncIterator()
    _ = try await iterator.next()
    _ = try await iterator.next()
    _ = try await iterator.next()

    let event = try RPCEnvelope(
      id: "event-id",
      type: .event,
      args: [],
      channel: RPCChannel.sessionEvent,
      seq: 42
    ).encodedString()
    await socket.serverSend(event)
    _ = try await iterator.next()

    let ack = try await RPCEnvelope.decode(socket.nextSentMessage())
    #expect(ack == RPCEnvelope(
      id: UUID(1).uuidString,
      type: .sequenceAck,
      lastSeq: 42
    ))

    await connection.close()
  }

  @Test
  func `publishes server push events`() async throws {
    let socket = TestRPCWebSocket()
    let client = makeClient(webSocketFactory: .mock(socket))

    let connection = try await connect(
      client,
      socket: socket,
      registeredChannels: [RPCChannel.sessionsGet]
    )
    var iterator = await (connection.events()).makeAsyncIterator()
    _ = try await iterator.next()
    _ = try await iterator.next()
    _ = try await iterator.next()

    let event = try RPCEnvelope(
      id: "event-id",
      type: .event,
      args: [.object(["type": .string("session_created"), "sessionId": .string("session-1")])],
      channel: RPCChannel.sessionEvent,
      seq: 42
    ).encodedString()
    await socket.serverSend(event)

    #expect(try await iterator.next() == .event(
      channel: RPCChannel.sessionEvent,
      args: [.object(["type": .string("session_created"), "sessionId": .string("session-1")])],
      seq: 42
    ))

    await connection.close()
  }

  @Test
  func `server connection closing late does not affect workspace connection`() async throws {
    let serverSocket = TestRPCWebSocket()
    let workspaceSocket = TestRPCWebSocket()
    let client = makeClient(webSocketFactory: .mock([serverSocket, workspaceSocket]))

    let serverConnection = try await connect(
      client,
      socket: serverSocket,
      registeredChannels: [RPCChannel.serverGetWorkspaces]
    )

    let workspaceConnectionTask = Task {
      try await client.connect(
        RPCConnectionRequest(
          url: #require(URL(string: "ws://desktop.local:9100")),
          token: "secret-token",
          workspaceID: "workspace-1"
        )
      )
    }
    _ = try await workspaceSocket.nextSentMessage()
    try await workspaceSocket.serverSend(RPCEnvelope(
      id: UUID(1).uuidString,
      type: .handshakeAck,
      clientId: "workspace-client",
      protocolVersion: "1.0",
      registeredChannels: [RPCChannel.sessionsGet]
    ).encodedString())
    let workspaceConnection = try await workspaceConnectionTask.value

    await serverSocket.serverFail(RPCClientError.disconnected)

    let sessions = Task {
      try await workspaceConnection.invokeJSON(channel: RPCChannel.sessionsGet)
    }
    let request = try await RPCEnvelope.decode(workspaceSocket.nextSentMessage())
    #expect(request.channel == RPCChannel.sessionsGet)

    try await workspaceSocket.serverSend(RPCEnvelope(
      id: UUID(2).uuidString,
      type: .response,
      channel: RPCChannel.sessionsGet,
      result: .array([])
    ).encodedString())
    #expect(try await sessions.value == JSONValue.array([]))

    await workspaceConnection.close()
    await serverConnection.close()
  }
}

private func connect(
  _ client: LiveRPCClient,
  socket: TestRPCWebSocket,
  registeredChannels: [String]
) async throws -> any RPCConnection {
  let connectionTask = Task {
    try await client.connect(
      RPCConnectionRequest(
        url: #require(URL(string: "ws://desktop.local:9100")),
        token: "secret-token"
      )
    )
  }

  _ = try await socket.nextSentMessage()
  try await socket.serverSend(RPCEnvelope(
    id: UUID(0).uuidString,
    type: .handshakeAck,
    clientId: "client-1",
    protocolVersion: "1.0",
    registeredChannels: registeredChannels
  ).encodedString())

  return try await connectionTask.value
}

private func makeClient(
  configuration: RPCClientConfiguration = RPCClientConfiguration(),
  webSocketFactory: RPCWebSocketFactory,
  clock: any NonsendingClock<Duration> = TestClock()
) -> LiveRPCClient {
  withDependencies {
    $0.continuousClock = clock
    $0.uuid = .incrementing
  } operation: {
    LiveRPCClient(
      configuration: configuration,
      webSocketFactory: webSocketFactory
    )
  }
}
