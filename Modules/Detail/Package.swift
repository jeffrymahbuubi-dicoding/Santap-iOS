// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Detail",
  defaultLocalization: "id",
  platforms: [.iOS(.v16), .macOS(.v13)],
  products: [
    .library(name: "Detail", targets: ["Detail"])
  ],
  dependencies: [
    .package(url: "https://github.com/jeffrymahbuubi-dicoding/SantapCore.git", from: "1.0.0"),
    .package(path: "../Common"),
    .package(path: "../Restaurant")
  ],
  targets: [
    .target(
      name: "Detail",
      dependencies: ["SantapCore", "Common", "Restaurant"]
    ),
    .testTarget(
      name: "DetailTests",
      dependencies: ["Detail"]
    )
  ]
)
