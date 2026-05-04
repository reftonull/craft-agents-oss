import ComposableArchitecture2
import Foundation

protocol RPCConnection: Sendable {
  func close() async
  func events() async -> AsyncThrowingStream<RPCConnectionEvent, any Error>
  func invokeJSON(channel: String, args: [JSONValue]) async throws -> JSONValue
}

extension RPCConnection {
  func invokeJSON(channel: String) async throws -> JSONValue {
    try await invokeJSON(channel: channel, args: [])
  }

  func invoke<T: Decodable>(
    _ type: T.Type = T.self,
    channel: String,
    args: [JSONValue] = []
  ) async throws -> T {
    try await invokeJSON(channel: channel, args: args).decode(T.self)
  }
}

actor LiveRPCClient {
  @Dependency(\.continuousClock) private var clock
  @Dependency(\.uuid) private var uuid

  private let configuration: RPCClientConfiguration
  private let webSocketFactory: RPCWebSocketFactory

  init(
    configuration: RPCClientConfiguration = RPCClientConfiguration(),
    webSocketFactory: RPCWebSocketFactory = .urlSession
  ) {
    self.configuration = configuration
    self.webSocketFactory = webSocketFactory
  }

  func connect(_ request: RPCConnectionRequest) async throws -> any RPCConnection {
    let connection = LiveRPCConnection(
      clock: clock,
      configuration: configuration,
      request: request,
      socket: webSocketFactory.makeWebSocket(for: request.url),
      uuid: uuid
    )
    do {
      try await connection.start()
      return connection
    } catch {
      await connection.close()
      throw error
    }
  }
}

actor LiveRPCConnection: RPCConnection {
  private typealias PendingResponse = AsyncThrowingStream<JSONValue, any Error>.Continuation

  private let clock: any NonsendingClock<Duration>
  private let configuration: RPCClientConfiguration
  private let eventContinuation: AsyncThrowingStream<RPCConnectionEvent, any Error>.Continuation
  private let eventStream: AsyncThrowingStream<RPCConnectionEvent, any Error>
  private let request: RPCConnectionRequest
  private let socket: any RPCWebSocket
  private let uuid: UUIDGenerator

  private var isClosed = false
  private var lastSeenSequence = 0
  private var pendingResponses: [String: PendingResponse] = [:]
  private var receiveTask: Task<Void, Never>?
  private var registeredChannels: Set<String>?

  init(
    clock: any NonsendingClock<Duration>,
    configuration: RPCClientConfiguration,
    request: RPCConnectionRequest,
    socket: any RPCWebSocket,
    uuid: UUIDGenerator
  ) {
    self.clock = clock
    self.configuration = configuration
    self.request = request
    self.socket = socket
    self.uuid = uuid

    var continuation: AsyncThrowingStream<RPCConnectionEvent, any Error>.Continuation!
    eventStream = AsyncThrowingStream<RPCConnectionEvent, any Error> { streamContinuation in
      continuation = streamContinuation
    }
    eventContinuation = continuation
  }

  func start() async throws {
    guard !isClosed else { throw RPCClientError.disconnected }

    eventContinuation.yield(.connecting)
    await socket.resume()

    eventContinuation.yield(.handshaking)
    let handshake = RPCEnvelope(
      id: uuid().uuidString,
      type: .handshake,
      clientCapabilities: request.clientCapabilities.isEmpty ? nil : request.clientCapabilities,
      protocolVersion: RPCProtocol.version,
      token: request.token,
      workspaceId: request.workspaceID
    )
    try await socket.send(handshake.encodedString())

    let acknowledgement = try await receiveEnvelope(
      timeout: configuration.connectTimeout,
      timeoutError: RPCClientError.connectTimedOut
    )
    guard acknowledgement.type == .handshakeAck else {
      throw RPCClientError.invalidServerResponse("Expected handshake_ack")
    }
    try handleHandshakeAck(acknowledgement)

    receiveTask = Task { [weak self] in
      guard let self else { return }
      await runReceiveLoop()
    }
  }

  func events() async -> AsyncThrowingStream<RPCConnectionEvent, any Error> {
    eventStream
  }

  func close() async {
    guard !isClosed else { return }
    isClosed = true

    receiveTask?.cancel()
    receiveTask = nil

    for id in Array(pendingResponses.keys) {
      finishPendingResponse(id: id, throwing: RPCClientError.disconnected)
    }

    await socket.close()
    eventContinuation.yield(.disconnected(RPCDisconnectInfo(reason: nil)))
    eventContinuation.finish()
  }

  func invokeJSON(channel: String, args: [JSONValue] = []) async throws -> JSONValue {
    guard !isClosed else { throw RPCClientError.disconnected }
    if let registeredChannels, !registeredChannels.contains(channel) {
      throw RPCClientError.channelUnavailable(channel)
    }

    let id = uuid().uuidString
    let envelope = RPCEnvelope(
      id: id,
      type: .request,
      args: args,
      channel: channel
    )
    let responseStream = registerPendingResponse(id: id)

    do {
      try await socket.send(envelope.encodedString())
      return try await waitForResponse(
        responseStream,
        requestID: id,
        timeout: configuration.requestTimeout,
        timeoutError: RPCClientError.requestTimedOut(channel: channel)
      )
    } catch {
      finishPendingResponse(id: id)
      throw error
    }
  }

  private func runReceiveLoop() async {
    do {
      while !Task.isCancelled {
        let envelope = try await receiveEnvelope()
        try await handle(envelope)
      }
    } catch is CancellationError {
      if !isClosed {
        eventContinuation.finish()
      }
    } catch {
      await failConnection(with: error)
    }
  }

  private func handle(_ envelope: RPCEnvelope) async throws {
    switch envelope.type {
    case .handshakeAck:
      try handleHandshakeAck(envelope)

    case .response:
      handleResponse(envelope)

    case .event:
      await handleEvent(envelope)

    case .error:
      throw envelope.error.map(RPCClientError.serverError)
        ?? RPCClientError.invalidServerResponse("Received error envelope without error payload")

    case .handshake, .request, .sequenceAck:
      break
    }
  }

  private func handleHandshakeAck(_ envelope: RPCEnvelope) throws {
    guard let clientID = envelope.clientId, !clientID.isEmpty else {
      throw RPCClientError.invalidServerResponse("Handshake acknowledgement did not include clientId")
    }

    if let serverProtocolVersion = envelope.protocolVersion {
      let serverMajor = serverProtocolVersion.split(separator: ".").first
      let clientMajor = RPCProtocol.version.split(separator: ".").first
      guard serverMajor == clientMajor else {
        throw RPCClientError.protocolMismatch(
          server: envelope.protocolVersion,
          client: RPCProtocol.version
        )
      }
    }

    let channels = envelope.registeredChannels.map(Set.init)
    registeredChannels = channels

    eventContinuation.yield(
      .connected(
        RPCConnectionInfo(
          clientID: clientID,
          protocolVersion: envelope.protocolVersion,
          registeredChannels: channels ?? [],
          reconnected: envelope.reconnected == true,
          serverVersion: envelope.serverVersion,
          stale: envelope.stale == true
        )
      )
    )
  }

  private func handleResponse(_ envelope: RPCEnvelope) {
    guard let response = pendingResponses.removeValue(forKey: envelope.id) else { return }

    if let error = envelope.error {
      response.finish(throwing: RPCClientError.serverError(error))
    } else {
      response.yield(envelope.result ?? .null)
      response.finish()
    }
  }

  private func handleEvent(_ envelope: RPCEnvelope) async {
    if let seq = envelope.seq {
      lastSeenSequence = max(lastSeenSequence, seq)
    }

    guard let channel = envelope.channel else { return }
    eventContinuation.yield(.event(channel: channel, args: envelope.args ?? [], seq: envelope.seq))

    if envelope.seq != nil {
      await sendSequenceAcknowledgement()
    }
  }

  private func receiveEnvelope(
    timeout: Duration? = nil,
    timeoutError: RPCClientError? = nil
  ) async throws -> RPCEnvelope {
    guard let timeout else {
      return try await RPCEnvelope.decode(socket.receive())
    }

    let clock = clock
    let socket = socket
    return try await withThrowingTaskGroup(of: RPCEnvelope.self) { group in
      group.addTask {
        try await RPCEnvelope.decode(socket.receive())
      }
      group.addTask {
        try await clock.sleep(for: timeout)
        throw timeoutError ?? RPCClientError.connectTimedOut
      }

      do {
        let envelope = try await group.next()!
        group.cancelAll()
        return envelope
      } catch {
        group.cancelAll()
        await socket.close()
        throw error
      }
    }
  }

  private func registerPendingResponse(id: String) -> AsyncThrowingStream<JSONValue, any Error> {
    AsyncThrowingStream { continuation in
      pendingResponses[id] = continuation
    }
  }

  private func waitForResponse(
    _ stream: AsyncThrowingStream<JSONValue, any Error>,
    requestID: String,
    timeout: Duration,
    timeoutError: RPCClientError
  ) async throws -> JSONValue {
    let clock = clock
    return try await withThrowingTaskGroup(of: JSONValue.self) { group in
      group.addTask {
        var iterator = stream.makeAsyncIterator()
        guard let value = try await iterator.next() else {
          throw RPCClientError.disconnected
        }
        return value
      }
      group.addTask {
        try await clock.sleep(for: timeout)
        throw timeoutError
      }

      do {
        let value = try await group.next()!
        group.cancelAll()
        finishPendingResponse(id: requestID)
        return value
      } catch {
        group.cancelAll()
        finishPendingResponse(id: requestID)
        throw error
      }
    }
  }

  private func sendSequenceAcknowledgement() async {
    guard lastSeenSequence > 0, !isClosed else { return }

    let envelope = RPCEnvelope(
      id: uuid().uuidString,
      type: .sequenceAck,
      lastSeq: lastSeenSequence
    )
    try? await socket.send(envelope.encodedString())
  }

  private func finishPendingResponse(id: String, throwing error: (any Error)? = nil) {
    guard let response = pendingResponses.removeValue(forKey: id) else { return }
    response.finish(throwing: error)
  }

  private func failConnection(with error: any Error) async {
    guard !isClosed else { return }
    isClosed = true

    receiveTask?.cancel()
    receiveTask = nil

    for id in Array(pendingResponses.keys) {
      finishPendingResponse(id: id, throwing: error)
    }

    await socket.close()
    eventContinuation.finish(throwing: error)
  }
}
