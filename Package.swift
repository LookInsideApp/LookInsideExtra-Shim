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
            url: "https://github.com/LookInsideApp/LookInside-Release/releases/download/0.1.8/LookInsideServer.xcframework.zip",
            checksum: "2b50926eac5283ef3af1d5ce8b42da6917e85fc4ee440caf932d80e4d3fb2648"
        ),
        .binaryTarget(
            name: "LookInsideServerDynamic",
            url: "https://github.com/LookInsideApp/LookInside-Release/releases/download/0.1.8/LookInsideServerDynamic.xcframework.zip",
            checksum: "417efec77956033f6c6c9a41d3d95eca6de0c494cb234026c63aa6dde3b01223"
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
