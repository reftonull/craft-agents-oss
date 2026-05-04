// swift-tools-version: 6.3

import PackageDescription

#if TUIST
  import ProjectDescription

  let packageSettings = PackageSettings(
    productTypes: [
      "ComposableArchitecture2": .framework,
    ]
  )
#endif

let package = Package(
  name: "AgentsMobileDependencies",
  platforms: [
    .iOS(.v17),
  ],
  dependencies: [
    .package(url: "git@github.com:pointfreeco/TCA26.git", branch: "main"),
  ]
)
