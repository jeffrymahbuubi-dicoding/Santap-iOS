// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Restaurant",
  platforms: [.iOS(.v16), .macOS(.v13)],
  products: [
    .library(name: "Restaurant", targets: ["Restaurant"])
  ],
  dependencies: [
    .package(url: "https://github.com/jeffrymahbuubi-dicoding/SantapCore.git", from: "1.0.0"),
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.12.2"),
    .package(path: "../Common")
  ],
  targets: [
    .target(
      name: "Restaurant",
      dependencies: [
        .product(name: "SantapCore", package: "SantapCore"),
        .product(name: "Alamofire", package: "Alamofire"),
        .product(name: "Common", package: "Common")
      ],
      resources: [.process("Data/Locale/Santap.xcdatamodeld")]
    ),
    .testTarget(
      name: "RestaurantTests",
      dependencies: ["Restaurant"],
      resources: [.process("Fixtures")]
    )
  ]
)
