import ProjectDescription

let project = Project(
  name: "AgentsMobile",
  organizationName: "Craft",
  options: .options(
    automaticSchemesOptions: .enabled(codeCoverageEnabled: true)
  ),
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.0",
      "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
      "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    ]
  ),
  targets: [
    .target(
      name: "AgentsMobile",
      destinations: [.iPhone, .iPad, .macCatalyst],
      product: .app,
      bundleId: "do.craft.agents.mobile",
      deploymentTargets: .iOS("26.0"),
      infoPlist: .extendingDefault(with: [
        "CFBundleDisplayName": "Agents Mobile",
        "NSAppTransportSecurity": [
          "NSAllowsLocalNetworking": true,
        ],
        "NSLocalNetworkUsageDescription": "Agents Mobile connects to the Craft Agents desktop app on your local network.",
        "UILaunchScreen": [:],
        "UISupportedInterfaceOrientations": [
          "UIInterfaceOrientationPortrait",
        ],
        "UISupportedInterfaceOrientations~ipad": [
          "UIInterfaceOrientationPortrait",
          "UIInterfaceOrientationPortraitUpsideDown",
          "UIInterfaceOrientationLandscapeLeft",
          "UIInterfaceOrientationLandscapeRight",
        ],
      ]),
      sources: ["Sources/AgentsMobile/**"],
      dependencies: [
        .external(name: "ComposableArchitecture2"),
        .external(name: "Sharing"),
      ]
    ),
    .target(
      name: "AgentsMobileTests",
      destinations: [.iPhone, .iPad, .macCatalyst],
      product: .unitTests,
      bundleId: "do.craft.agents.mobile.tests",
      deploymentTargets: .iOS("26.0"),
      infoPlist: .default,
      sources: ["Tests/AgentsMobileTests/**"],
      dependencies: [
        .target(name: "AgentsMobile"),
      ]
    ),
  ]
)
