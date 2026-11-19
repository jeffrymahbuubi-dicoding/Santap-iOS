// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "About",
  defaultLocalization: "id",
  platforms: [.iOS(.v16), .macOS(.v13)],
  products: [
    .library(name: "About", targets: ["About"])
  ],
  dependencies: [
    .package(url: "https://github.com/jeffrymahbuubi-dicoding/SantapCore.git", from: "1.0.0"),
    .package(path: "../Common")
  ],
  targets: [
    .target(
      name: "About",
      dependencies: ["SantapCore", "Common"]
    ),
    .testTarget(
      name: "AboutTests",
      dependencies: ["About"]
    )
  ]
)
