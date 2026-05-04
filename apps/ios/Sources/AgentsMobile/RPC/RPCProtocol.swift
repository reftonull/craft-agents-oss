import Foundation

/// Stable channel names exposed by the Craft Agents desktop server.
enum RPCChannel {
  static let serverGetWorkspaces = "server:getWorkspaces"
  static let sessionEvent = "session:event"
  static let sessionsGet = "sessions:get"
  static let sessionsGetMessages = "sessions:getMessages"
  static let sessionsSendMessage = "sessions:sendMessage"
}

enum RPCProtocol {
  static let version = "1.0"
}

enum RPCMessageType: String, Codable, Equatable, Sendable {
  case error
  case event
  case handshake
  case handshakeAck = "handshake_ack"
  case request
  case response
  case sequenceAck = "sequence_ack"
}

struct RPCWireError: Codable, Equatable, Error, Sendable {
  var code: String
  var data: JSONValue?
  var message: String
}

struct RPCEnvelope: Codable, Equatable, Sendable {
  var args: [JSONValue]?
  var channel: String?
  var clientCapabilities: [String]?
  var clientId: String?
  var error: RPCWireError?
  var id: String
  var lastSeq: Int?
  var protocolVersion: String?
  var reconnectClientId: String?
  var reconnected: Bool?
  var registeredChannels: [String]?
  var result: JSONValue?
  var seq: Int?
  var serverId: String?
  var serverVersion: String?
  var stale: Bool?
  var token: String?
  var type: RPCMessageType
  var webContentsId: Int?
  var workspaceId: String?

  init(
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

extension RPCEnvelope {
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
