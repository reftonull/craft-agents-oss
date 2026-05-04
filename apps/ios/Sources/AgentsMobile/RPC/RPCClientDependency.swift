import ComposableArchitecture2
import Foundation

struct RPCClient: Sendable {
  var connect: @Sendable (RPCConnectionRequest) async throws -> any RPCConnection
}

extension RPCClient: DependencyKey {
  static var liveValue: RPCClient {
    let client = LiveRPCClient()
    return RPCClient(
      connect: { request in try await client.connect(request) }
    )
  }

  static var testValue: RPCClient {
    RPCClient(
      connect: { _ in throw RPCClientError.unimplemented }
    )
  }
}

extension DependencyValues {
  var rpcClient: RPCClient {
    get { self[RPCClient.self] }
    set { self[RPCClient.self] = newValue }
  }
}
