// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LookInsideExtra-Shim",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "LookInsideExtraSwiftUserInterfaceSupport",
            targets: ["LookInsideExtraSwiftUserInterfaceSupport", "LookInsideExtraSwiftUserInterfaceSupportPackageShim"]
        ),
        .library(
            name: "LookInsideAuthenticator",
            targets: ["LookInsideAuthenticator", "LookInsideAuthenticatorPackageShim"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "LookInsideExtraSwiftUserInterfaceSupport",
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideExtraSwiftUserInterfaceSupport.xcframework.zip",
            checksum: "aea09454cb09c707eaa75cc03d3feebe2a59a53956b0b72e078cecb3ab72e82b"
        ),
        .target(
            name: "LookInsideExtraSwiftUserInterfaceSupportPackageShim",
            dependencies: ["LookInsideExtraSwiftUserInterfaceSupport"],
            path: "Sources/LookInsideExtraSwiftUserInterfaceSupportPackageShim"
        ),
        .binaryTarget(
            name: "LookInsideAuthenticator",
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideAuthenticator.xcframework.zip",
            checksum: "da261dfc05bef35b51c70d037532c3fbbd7e213aedc06e6b262757396a163ef6"
        ),
        .target(
            name: "LookInsideAuthenticatorPackageShim",
            dependencies: ["LookInsideAuthenticator"],
            path: "Sources/LookInsideAuthenticatorPackageShim"
        ),
        .testTarget(
            name: "LookInsideExtraShimTests",
            dependencies: ["LookInsideExtraSwiftUserInterfaceSupportPackageShim", "LookInsideAuthenticatorPackageShim"],
            path: "Tests/LookInsideExtraShimTests"
        )
    ]
)
