import Foundation

public protocol RPCWebSocket: Sendable {
  func close() async
  func receive() async throws -> String
  func resume() async
  func send(_ string: String) async throws
}

public struct RPCWebSocketFactory: Sendable {
  public var makeWebSocket: @Sendable (URL) -> any RPCWebSocket

  public init(makeWebSocket: @escaping @Sendable (URL) -> any RPCWebSocket) {
    self.makeWebSocket = makeWebSocket
  }

  public func makeWebSocket(for url: URL) -> any RPCWebSocket {
    makeWebSocket(url)
  }
}

public extension RPCWebSocketFactory {
  static var urlSession: RPCWebSocketFactory {
    RPCWebSocketFactory { url in
      URLSessionRPCWebSocket(url: url)
    }
  }
}

private final class URLSessionRPCWebSocket: RPCWebSocket, @unchecked Sendable {
  private let task: URLSessionWebSocketTask

  init(url: URL) {
    task = URLSession.shared.webSocketTask(with: url)
  }

  func close() async {
    task.cancel(with: .goingAway, reason: nil)
  }

  func receive() async throws -> String {
    switch try await task.receive() {
    case let .data(data):
      guard let string = String(data: data, encoding: .utf8) else {
        throw RPCClientError.invalidServerResponse("Received non-UTF8 WebSocket data")
      }
      return string

    case let .string(string):
      return string

    @unknown default:
      throw RPCClientError.invalidServerResponse("Received unknown WebSocket message")
    }
  }

  func resume() async {
    task.resume()
  }

  func send(_ string: String) async throws {
    try await task.send(.string(string))
  }
}
