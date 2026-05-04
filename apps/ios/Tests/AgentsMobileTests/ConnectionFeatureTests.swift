@testable import AgentsMobile
import Foundation
import Testing

@Suite("ConnectionFeature")
struct ConnectionFeatureTests {
  @Test("normalizes host and HTTP URLs to WebSocket URLs")
  func normalizesWebSocketURLs() throws {
    #expect(try ConnectionFeature.normalizedWebSocketURL("192.168.1.10:9100").absoluteString == "ws://192.168.1.10:9100")
    #expect(try ConnectionFeature.normalizedWebSocketURL("http://desktop.local:9100").absoluteString == "ws://desktop.local:9100")
    #expect(try ConnectionFeature.normalizedWebSocketURL("https://desktop.local:9100").absoluteString == "wss://desktop.local:9100")
  }

  @Test("rejects bind-all address as a client target")
  func rejectsBindAllAddress() {
    #expect(throws: URLError.self) {
      try ConnectionFeature.normalizedWebSocketURL("ws://0.0.0.0:9100")
    }
  }
}
