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
            checksum: "48a79dce0843fbed876bf500bb245a5149c8b1116e5c5e4f6c0a17a2f3f4acac"
        ),
        .target(
            name: "LookInsideExtraSwiftUserInterfaceSupportPackageShim",
            dependencies: ["LookInsideExtraSwiftUserInterfaceSupport"],
            path: "Sources/LookInsideExtraSwiftUserInterfaceSupportPackageShim"
        ),
        .binaryTarget(
            name: "LookInsideAuthenticator",
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideAuthenticator.xcframework.zip",
            checksum: "86729cd1f9f8c1f42a9272b451a75ab7e0a7348cd41edd7b17ee29d7238f9d2d"
        ),
        .target(
            name: "LookInsideAuthenticatorPackageShim",
            dependencies: ["LookInsideAuthenticator"],
            path: "Sources/LookInsideAuthenticatorPackageShim"
        )
    ]
)
