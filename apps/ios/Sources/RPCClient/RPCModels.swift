import Foundation

public struct RPCClientConfiguration: Equatable, Sendable {
  public var connectTimeout: Duration
  public var requestTimeout: Duration

  public init(
    connectTimeout: Duration = .seconds(10),
    requestTimeout: Duration = .seconds(30)
  ) {
    self.connectTimeout = connectTimeout
    self.requestTimeout = requestTimeout
  }
}

public struct RPCConnectionInfo: Equatable, Sendable {
  public var clientID: String
  public var protocolVersion: String?
  public var registeredChannels: Set<String>
  public var reconnected: Bool
  public var serverVersion: String?
  public var stale: Bool

  public init(
    clientID: String,
    protocolVersion: String?,
    registeredChannels: Set<String>,
    reconnected: Bool,
    serverVersion: String?,
    stale: Bool
  ) {
    self.clientID = clientID
    self.protocolVersion = protocolVersion
    self.registeredChannels = registeredChannels
    self.reconnected = reconnected
    self.serverVersion = serverVersion
    self.stale = stale
  }
}

public struct RPCConnectionRequest: Equatable, Sendable {
  public var clientCapabilities: [String]
  public var token: String
  public var url: URL
  public var workspaceID: String?

  public init(
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

public struct RPCDisconnectInfo: Equatable, Sendable {
  public var reason: String?

  public init(reason: String?) {
    self.reason = reason
  }
}

public enum RPCConnectionEvent: Equatable, Sendable {
  case connecting
  case connected(RPCConnectionInfo)
  case disconnected(RPCDisconnectInfo)
  case event(channel: String, args: [JSONValue], seq: Int?)
  case handshaking
}

public enum RPCClientError: Error, Equatable, Sendable {
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
