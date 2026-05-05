// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "AgentsMobilePackage",
  platforms: [
    .iOS(.v26),
  ],
  products: [
    .library(name: "AgentsMobileCore", targets: ["AgentsMobileCore"]),
  ],
  dependencies: [
    .package(url: "git@github.com:pointfreeco/TCA26.git", branch: "main"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.0.0"),
  ],
  targets: [
    .target(
      name: "AgentsMobileCore",
      dependencies: [
        .product(name: "ComposableArchitecture2", package: "TCA26"),
        .product(name: "Sharing", package: "swift-sharing"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ],
      path: "Sources/AgentsMobile"
    )
  ]
)
