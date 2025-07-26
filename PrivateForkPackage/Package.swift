// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrivateForkFeature",
    platforms: [.macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PrivateForkFeature",
            targets: ["PrivateForkFeature"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/OAuthSwift/OAuthSwift.git", from: "2.2.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PrivateForkFeature",
            dependencies: ["OAuthSwift"]
        ),
        .testTarget(
            name: "PrivateForkFeatureTests",
            dependencies: [
                "PrivateForkFeature"
            ]
        )
    ]
)
