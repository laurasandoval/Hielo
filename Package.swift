// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Hielo",
  platforms: [
    .iOS(.v26),
  ],
  products: [
    .library(
      name: "Hielo",
      targets: ["Hielo"]
    ),
  ],
  targets: [
    .target(name: "Hielo"),
    .testTarget(
      name: "HieloTests",
      dependencies: ["Hielo"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
