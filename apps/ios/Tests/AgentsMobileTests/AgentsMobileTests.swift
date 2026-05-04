@testable import AgentsMobile
import Testing

@Suite("AgentsMobile")
struct AgentsMobileTests {
  @Test("test target uses Swift Testing")
  func swiftTestingIsAvailable() {
    #expect(true)
  }
}
