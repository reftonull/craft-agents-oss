import ComposableArchitecture2
import Foundation

public struct RPCClient: Sendable {
  public var connect: @Sendable (RPCConnectionRequest) async throws -> any RPCConnection

  public init(connect: @escaping @Sendable (RPCConnectionRequest) async throws -> any RPCConnection) {
    self.connect = connect
  }
}

extension RPCClient: DependencyKey {
  public static var liveValue: RPCClient {
    let client = LiveRPCClient()
    return RPCClient(
      connect: { request in try await client.connect(request) }
    )
  }

  public static var testValue: RPCClient {
    RPCClient(
      connect: { _ in throw RPCClientError.unimplemented }
    )
  }
}

public extension DependencyValues {
  var rpcClient: RPCClient {
    get { self[RPCClient.self] }
    set { self[RPCClient.self] = newValue }
  }
}
