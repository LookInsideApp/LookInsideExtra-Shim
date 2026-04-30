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
            url: "https://github.com/LookInsideApp/LookInside-Release/releases/download/0.1.10/LookInsideServer.xcframework.zip",
            checksum: "257d419b3487fc24a9b187ecf7e71080faa99e5e75b0dc9eb68e1d8e013b2472"
        ),
        .binaryTarget(
            name: "LookInsideServerDynamic",
            url: "https://github.com/LookInsideApp/LookInside-Release/releases/download/0.1.10/LookInsideServerDynamic.xcframework.zip",
            checksum: "f8504afa0b19c094f3e6926a7a6718e85bda2dc93e86186aedb57bc7d6f06213"
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
