import Foundation

/// Stable channel names exposed by the Craft Agents desktop server.
public enum RPCChannel {
  public static let serverGetWorkspaces = "server:getWorkspaces"
  public static let sessionEvent = "session:event"
  public static let sessionsGet = "sessions:get"
  public static let sessionsGetMessages = "sessions:getMessages"
  public static let sessionsSendMessage = "sessions:sendMessage"
}

public enum RPCProtocol {
  public static let version = "1.0"
}

public enum RPCMessageType: String, Codable, Equatable, Sendable {
  case error
  case event
  case handshake
  case handshakeAck = "handshake_ack"
  case request
  case response
  case sequenceAck = "sequence_ack"
}

public struct RPCWireError: Codable, Equatable, Error, Sendable {
  public var code: String
  public var data: JSONValue?
  public var message: String

  public init(code: String, data: JSONValue? = nil, message: String) {
    self.code = code
    self.data = data
    self.message = message
  }
}

public struct RPCEnvelope: Codable, Equatable, Sendable {
  public var args: [JSONValue]?
  public var channel: String?
  public var clientCapabilities: [String]?
  public var clientId: String?
  public var error: RPCWireError?
  public var id: String
  public var lastSeq: Int?
  public var protocolVersion: String?
  public var reconnectClientId: String?
  public var reconnected: Bool?
  public var registeredChannels: [String]?
  public var result: JSONValue?
  public var seq: Int?
  public var serverId: String?
  public var serverVersion: String?
  public var stale: Bool?
  public var token: String?
  public var type: RPCMessageType
  public var webContentsId: Int?
  public var workspaceId: String?

  public init(
    id: String,
    type: RPCMessageType,
    args: [JSONValue]? = nil,
    channel: String? = nil,
    clientCapabilities: [String]? = nil,
    clientId: String? = nil,
    error: RPCWireError? = nil,
    lastSeq: Int? = nil,
    protocolVersion: String? = nil,
    reconnectClientId: String? = nil,
    reconnected: Bool? = nil,
    registeredChannels: [String]? = nil,
    result: JSONValue? = nil,
    seq: Int? = nil,
    serverId: String? = nil,
    serverVersion: String? = nil,
    stale: Bool? = nil,
    token: String? = nil,
    webContentsId: Int? = nil,
    workspaceId: String? = nil
  ) {
    self.args = args
    self.channel = channel
    self.clientCapabilities = clientCapabilities
    self.clientId = clientId
    self.error = error
    self.id = id
    self.lastSeq = lastSeq
    self.protocolVersion = protocolVersion
    self.reconnectClientId = reconnectClientId
    self.reconnected = reconnected
    self.registeredChannels = registeredChannels
    self.result = result
    self.seq = seq
    self.serverId = serverId
    self.serverVersion = serverVersion
    self.stale = stale
    self.token = token
    self.type = type
    self.webContentsId = webContentsId
    self.workspaceId = workspaceId
  }
}

public extension RPCEnvelope {
  static func decode(_ rawValue: String) throws -> RPCEnvelope {
    try JSONDecoder.craftRPC.decode(RPCEnvelope.self, from: Data(rawValue.utf8))
  }

  func encodedString() throws -> String {
    let data = try JSONEncoder.craftRPC.encode(self)
    guard let string = String(data: data, encoding: .utf8) else {
      throw RPCClientError.encodingFailed
    }
    return string
  }
}
