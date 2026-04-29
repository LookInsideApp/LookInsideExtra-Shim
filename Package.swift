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
            url: "https://github.com/LookInsideApp/LookInside-Release/releases/download/storage/LookInsideServer.xcframework.zip?sha256=e6dcc9fdd2f2f3c245f924f290f151bd12b3b339c752c945675518f654afd7af",
            checksum: "e6dcc9fdd2f2f3c245f924f290f151bd12b3b339c752c945675518f654afd7af"
        ),
        .binaryTarget(
            name: "LookInsideServerDynamic",
            url: "https://github.com/LookInsideApp/LookInside-Release/releases/download/storage/LookInsideServerDynamic.xcframework.zip?sha256=a5945c032b449eaf68c91fabba7f4bc2f1fb620a8674fe4ac608dce2a9900cf3",
            checksum: "a5945c032b449eaf68c91fabba7f4bc2f1fb620a8674fe4ac608dce2a9900cf3"
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
