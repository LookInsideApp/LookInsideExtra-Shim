// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LookInside-Release",
    platforms: [
        .iOS("15.0"),
        .macOS("15.0"),
    ],
    products: [
        .library(
            name: "LookInsideServerStatic",
            targets: ["LookInsideServerStatic"]
        ),
        .library(
            name: "LookInsideServerDynamic",
            targets: ["LookInsideServerDynamic"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "LookInsideServerStatic",
            url: "https://github.com/LookInsideApp/LookInside-Release/releases/download/0.1.6/LookInsideServer.xcframework.zip",
            checksum: "29986fd5b4d72582cf8f6da7de7b3ee86ba6180997afac7f7c0eaaeb1822bdb9"
        ),
        .binaryTarget(
            name: "LookInsideServerDynamic",
            url: "https://github.com/LookInsideApp/LookInside-Release/releases/download/0.1.6/LookInsideServerDynamic.xcframework.zip",
            checksum: "e9235493b27ebae3dc82e56610b8af5388d77498ff5b17c23eb973673cb8a9dc"
        ),
        .testTarget(
            name: "LookInsideReleaseStaticTests",
            dependencies: ["LookInsideServerStatic"],
            path: "Tests/LookInsideReleaseStaticTests"
        ),
        .testTarget(
            name: "LookInsideReleaseDynamicTests",
            dependencies: ["LookInsideServerDynamic"],
            path: "Tests/LookInsideReleaseDynamicTests"
        )
    ]
)
