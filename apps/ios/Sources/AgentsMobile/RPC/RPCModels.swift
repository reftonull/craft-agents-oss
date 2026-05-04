import Foundation

struct RPCClientConfiguration: Equatable, Sendable {
  var connectTimeout: Duration
  var requestTimeout: Duration

  init(
    connectTimeout: Duration = .seconds(10),
    requestTimeout: Duration = .seconds(30)
  ) {
    self.connectTimeout = connectTimeout
    self.requestTimeout = requestTimeout
  }
}

struct RPCConnectionInfo: Equatable, Sendable {
  var clientID: String
  var protocolVersion: String?
  var registeredChannels: Set<String>
  var reconnected: Bool
  var serverVersion: String?
  var stale: Bool
}

struct RPCConnectionRequest: Equatable, Sendable {
  var clientCapabilities: [String]
  var token: String
  var url: URL
  var workspaceID: String?

  init(
    url: URL,
    token: String,
    workspaceID: String? = nil,
    clientCapabilities: [String] = []
  ) {
    self.clientCapabilities = clientCapabilities
    self.token = token
    self.url = url
    self.workspaceID = workspaceID
  }
}

struct RPCDisconnectInfo: Equatable, Sendable {
  var reason: String?
}

enum RPCConnectionEvent: Equatable, Sendable {
  case connecting
  case connected(RPCConnectionInfo)
  case disconnected(RPCDisconnectInfo)
  case event(channel: String, args: [JSONValue], seq: Int?)
  case handshaking
}

enum RPCClientError: Error, Equatable, Sendable {
  case channelUnavailable(String)
  case disconnected
  case connectTimedOut
  case encodingFailed
  case invalidServerResponse(String)
  case notConnected
  case protocolMismatch(server: String?, client: String)
  case requestTimedOut(channel: String)
  case serverError(RPCWireError)
  case unimplemented
}
