// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Common",
  defaultLocalization: "id",
  platforms: [.iOS(.v16), .macOS(.v13)],
  products: [
    .library(name: "Common", targets: ["Common"])
  ],
  targets: [
    .target(
      name: "Common",
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "CommonTests",
      dependencies: ["Common"]
    )
  ]
)
