@testable import AgentsMobile
import Foundation

actor TestRPCWebSocket: RPCWebSocket {
  private var receiveContinuations: [CheckedContinuation<String, any Error>] = []
  private var receivedMessages: [Result<String, any Error>] = []
  private var sentContinuations: [CheckedContinuation<String, any Error>] = []
  private var sentMessages: [String] = []
  private var isClosed = false

  private(set) var closeCount = 0
  private(set) var resumeCount = 0

  func close() async {
    closeCount += 1
    isClosed = true

    for continuation in receiveContinuations {
      continuation.resume(throwing: CancellationError())
    }
    receiveContinuations.removeAll()
  }

  func receive() async throws -> String {
    if isClosed { throw CancellationError() }

    if !receivedMessages.isEmpty {
      return try receivedMessages.removeFirst().get()
    }

    return try await withCheckedThrowingContinuation { continuation in
      receiveContinuations.append(continuation)
    }
  }

  func resume() async {
    resumeCount += 1
  }

  func send(_ string: String) async throws {
    if !sentContinuations.isEmpty {
      sentContinuations.removeFirst().resume(returning: string)
    } else {
      sentMessages.append(string)
    }
  }

  func nextSentMessage() async throws -> String {
    if !sentMessages.isEmpty {
      return sentMessages.removeFirst()
    }

    return try await withCheckedThrowingContinuation { continuation in
      sentContinuations.append(continuation)
    }
  }

  func serverSend(_ string: String) {
    guard !isClosed else { return }

    if !receiveContinuations.isEmpty {
      receiveContinuations.removeFirst().resume(returning: string)
    } else {
      receivedMessages.append(.success(string))
    }
  }

  func serverFail(_ error: any Error) {
    guard !isClosed else { return }

    if !receiveContinuations.isEmpty {
      receiveContinuations.removeFirst().resume(throwing: error)
    } else {
      receivedMessages.append(.failure(error))
    }
  }
}

extension RPCWebSocketFactory {
  static func test(_ socket: TestRPCWebSocket) -> RPCWebSocketFactory {
    RPCWebSocketFactory { _ in socket }
  }

  static func test(_ sockets: [TestRPCWebSocket]) -> RPCWebSocketFactory {
    let sockets = SocketQueue(sockets)
    return RPCWebSocketFactory { _ in sockets.next() }
  }
}

private final class SocketQueue: @unchecked Sendable {
  private let lock = NSLock()
  private var sockets: [TestRPCWebSocket]

  init(_ sockets: [TestRPCWebSocket]) {
    self.sockets = sockets
  }

  func next() -> TestRPCWebSocket {
    lock.lock()
    defer { lock.unlock() }
    guard !sockets.isEmpty else { fatalError("No test sockets remaining") }
    return sockets.removeFirst()
  }
}
