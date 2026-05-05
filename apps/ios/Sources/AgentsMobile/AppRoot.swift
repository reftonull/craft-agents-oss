import ComposableArchitecture2
import UIKit

@MainActor
public func makeAgentsMobileRootViewController() -> UIViewController {
  let store = Store(initialState: AppFeature.State()) {
    AppFeature()
  }
  return AppViewController(store: store)
}
