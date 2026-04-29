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
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideExtraSwiftUserInterfaceSupport.xcframework.zip?sha256=5a7e013e846c0bb2d444aafc74adb018356dfb346d122512d6cac450e0f6a206",
            checksum: "5a7e013e846c0bb2d444aafc74adb018356dfb346d122512d6cac450e0f6a206"
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
