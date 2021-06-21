// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kitsunebi",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "Kitsunebi",
            targets: ["Kitsunebi"]),
    ],
    targets: [
        .target(
            name: "Kitsunebi",
            resources: [
                .process("default.metal")
            ]
        ),
        .testTarget(
            name: "KitsunebiTests",
            dependencies: ["Kitsunebi"]
        ),
    ]
)
