@testable import AgentsMobileCore
import Foundation
import Testing

@Suite("RPC protocol")
struct RPCProtocolTests {
  @Test
  func `encodes handshake envelope expected by the desktop server`() throws {
    let envelope = RPCEnvelope(
      id: "handshake-id",
      type: .handshake,
      clientCapabilities: ["mobile:example"],
      protocolVersion: "1.0",
      token: "secret-token",
      workspaceId: "workspace-1"
    )

    let rawValue = try envelope.encodedString()

    #expect(rawValue == """
    {"clientCapabilities":["mobile:example"],"id":"handshake-id","protocolVersion":"1.0","token":"secret-token","type":"handshake","workspaceId":"workspace-1"}
    """)
  }

  @Test
  func `decodes handshake acknowledgement`() throws {
    let envelope = try RPCEnvelope.decode("""
    {
      "id": "handshake-id",
      "type": "handshake_ack",
      "protocolVersion": "1.0",
      "clientId": "client-1",
      "serverVersion": "0.1.0",
      "registeredChannels": ["server:getWorkspaces", "sessions:get"]
    }
    """)

    #expect(envelope.type == .handshakeAck)
    #expect(envelope.clientId == "client-1")
    #expect(envelope.registeredChannels == ["server:getWorkspaces", "sessions:get"])
  }
}
