// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Favorite",
  defaultLocalization: "id",
  platforms: [.iOS(.v16), .macOS(.v13)],
  products: [
    .library(name: "Favorite", targets: ["Favorite"])
  ],
  dependencies: [
    .package(url: "https://github.com/jeffrymahbuubi-dicoding/SantapCore.git", from: "1.0.0"),
    .package(path: "../Common"),
    .package(path: "../Restaurant")
  ],
  targets: [
    .target(
      name: "Favorite",
      dependencies: ["SantapCore", "Common", "Restaurant"]
    ),
    .testTarget(
      name: "FavoriteTests",
      dependencies: ["Favorite"]
    )
  ]
)
