// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "KeyboardFreeze",
  platforms: [
    .iOS(.v26),
  ],
  products: [
    .library(
      name: "KeyboardFreeze",
      targets: ["KeyboardFreeze"]
    ),
  ],
  targets: [
    .target(name: "KeyboardFreeze"),
    .testTarget(
      name: "KeyboardFreezeTests",
      dependencies: ["KeyboardFreeze"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
