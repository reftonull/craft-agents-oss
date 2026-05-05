// swift-tools-version: 6.3

import PackageDescription

#if TUIST
  import ProjectDescription

  let packageSettings = PackageSettings(
    productTypes: [
      "ComposableArchitecture2": .framework,
      "Sharing": .framework,
    ]
  )
#endif

let package = Package(
  name: "AgentsMobileDependencies",
  platforms: [
    .iOS(.v26),
  ],
  dependencies: [
    .package(url: "git@github.com:pointfreeco/TCA26.git", branch: "main"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.0.0"),
  ]
)
