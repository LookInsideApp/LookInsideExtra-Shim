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
            url: "https://github.com/LookInsideApp/LookInside-Release/releases/download/0.1.13/LookInsideServer.xcframework.zip",
            checksum: "3ffe5070eba0f0448e8f9ce78462cfe3a03227b5987e8507467b1ec017b1e8dc"
        ),
        .binaryTarget(
            name: "LookInsideServerDynamic",
            url: "https://github.com/LookInsideApp/LookInside-Release/releases/download/0.1.13/LookInsideServerDynamic.xcframework.zip",
            checksum: "aa8b388470357cfb745361b9b4b6aa4368cf6788c740193fbc58d916483cbbf4"
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
