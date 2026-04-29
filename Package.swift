// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LookInsideExtra-Shim",
    platforms: [
        .iOS("15.0"),
        .macOS("15.0"),
    ],
    products: [
        .library(
            name: "LookInsideExtraSwiftUserInterfaceSupport",
            targets: ["LookInsideExtraSwiftUserInterfaceSupport", "LookInsideExtraSwiftUserInterfaceSupportPackageShim"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/LookInsideApp/LookInsideServer.git", branch: "main"),
    ],
    targets: [
        .binaryTarget(
            name: "LookInsideExtraSwiftUserInterfaceSupport",
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideExtraSwiftUserInterfaceSupport.xcframework.zip?sha256=458f5fa2ca9cf98589d5f1e9f75ec2b044f057fa07e7741553141dd5f4da7a65",
            checksum: "458f5fa2ca9cf98589d5f1e9f75ec2b044f057fa07e7741553141dd5f4da7a65"
        ),
        .target(
            name: "LookInsideExtraSwiftUserInterfaceSupportPackageShim",
            dependencies: ["LookInsideExtraSwiftUserInterfaceSupport", .product(name: "LookinServer", package: "LookInsideServer")],
            path: "Sources/LookInsideExtraSwiftUserInterfaceSupportPackageShim"
        ),
        .testTarget(
            name: "LookInsideExtraShimTests",
            dependencies: ["LookInsideExtraSwiftUserInterfaceSupportPackageShim"],
            path: "Tests/LookInsideExtraShimTests"
        )
    ]
)
