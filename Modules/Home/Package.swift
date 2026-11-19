// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Home",
  defaultLocalization: "id",
  platforms: [.iOS(.v16), .macOS(.v13)],
  products: [
    .library(name: "Home", targets: ["Home"])
  ],
  dependencies: [
    .package(url: "https://github.com/jeffrymahbuubi-dicoding/SantapCore.git", from: "1.0.0"),
    .package(path: "../Common"),
    .package(path: "../Restaurant")
  ],
  targets: [
    .target(
      name: "Home",
      dependencies: ["SantapCore", "Common", "Restaurant"]
    ),
    .testTarget(
      name: "HomeTests",
      dependencies: ["Home"]
    )
  ]
)
