// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "AgentsMobilePackage",
  platforms: [
    .iOS(.v26),
  ],
  products: [
    .library(name: "AppFeature", targets: ["AppFeature"]),
    .library(name: "ClientModels", targets: ["ClientModels"]),
    .library(name: "ConnectionFeature", targets: ["ConnectionFeature"]),
    .library(name: "Database", targets: ["Database"]),
    .library(name: "RPCClient", targets: ["RPCClient"]),
  ],
  dependencies: [
    .package(url: "git@github.com:pointfreeco/TCA26.git", branch: "main"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.0"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.3.0"),
  ],
  targets: [
    .target(
      name: "AppFeature",
      dependencies: [
        "ClientModels",
        "ConnectionFeature",
        "Database",
        "RPCClient",
        .product(name: "ComposableArchitecture2", package: "TCA26"),
        .product(name: "Sharing", package: "swift-sharing"),
      ]
    ),
    .testTarget(
      name: "AppFeatureTests",
      dependencies: [
        "AppFeature",
        "ClientModels",
        "ConnectionFeature",
        "Database",
        "RPCClient",
        .product(name: "ComposableArchitecture2", package: "TCA26"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "Sharing", package: "swift-sharing"),
      ]
    ),
    .target(
      name: "ClientModels"
    ),
    .target(
      name: "ConnectionFeature",
      dependencies: [
        "ClientModels",
        "RPCClient",
        .product(name: "ComposableArchitecture2", package: "TCA26"),
      ]
    ),
    .testTarget(
      name: "ConnectionFeatureTests",
      dependencies: [
        "ClientModels",
        "ConnectionFeature",
        "RPCClient",
        .product(name: "ComposableArchitecture2", package: "TCA26"),
      ]
    ),
    .target(
      name: "Database",
      dependencies: [
        "ClientModels",
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "Sharing", package: "swift-sharing"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .testTarget(
      name: "DatabaseTests",
      dependencies: [
        "ClientModels",
        "Database",
        .product(name: "Sharing", package: "swift-sharing"),
        .product(name: "SQLiteDataTestSupport", package: "sqlite-data"),
      ]
    ),
    .target(
      name: "RPCClient",
      dependencies: [
        .product(name: "ComposableArchitecture2", package: "TCA26"),
      ]
    ),
    .testTarget(
      name: "RPCClientTests",
      dependencies: [
        "RPCClient",
      ]
    ),
  ]
)
