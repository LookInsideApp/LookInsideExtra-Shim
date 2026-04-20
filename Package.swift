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
        ),
        .library(
            name: "LookInsideAuthenticator",
            targets: ["LookInsideAuthenticator", "LookInsideAuthenticatorPackageShim"]
        ),
        .library(
            name: "LookInsideAuthenticatorUI",
            targets: ["LookInsideAuthenticatorUI", "LookInsideAuthenticatorUIPackageShim"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "LookInsideExtraSwiftUserInterfaceSupport",
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideExtraSwiftUserInterfaceSupport.xcframework.zip?sha256=558205222e163ad8af462c8b5ffc82bda15d7557a833143296cdf409c90a1991",
            checksum: "558205222e163ad8af462c8b5ffc82bda15d7557a833143296cdf409c90a1991"
        ),
        .target(
            name: "LookInsideExtraSwiftUserInterfaceSupportPackageShim",
            dependencies: ["LookInsideExtraSwiftUserInterfaceSupport"],
            path: "Sources/LookInsideExtraSwiftUserInterfaceSupportPackageShim"
        ),
        .binaryTarget(
            name: "LookInsideAuthenticator",
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideAuthenticator.xcframework.zip?sha256=f408fab7e8c808b79085b54e716fc2e077b9574d80811d84174c03ce23e8c056",
            checksum: "f408fab7e8c808b79085b54e716fc2e077b9574d80811d84174c03ce23e8c056"
        ),
        .target(
            name: "LookInsideAuthenticatorPackageShim",
            dependencies: ["LookInsideAuthenticator"],
            path: "Sources/LookInsideAuthenticatorPackageShim"
        ),
        .binaryTarget(
            name: "LookInsideAuthenticatorUI",
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideAuthenticatorUI.xcframework.zip?sha256=83d4f0c5fc043b71e2e78b9d31639046f50ab088b3c9bca2efc385b88f5e5df3",
            checksum: "83d4f0c5fc043b71e2e78b9d31639046f50ab088b3c9bca2efc385b88f5e5df3"
        ),
        .target(
            name: "LookInsideAuthenticatorUIPackageShim",
            dependencies: ["LookInsideAuthenticatorUI"],
            path: "Sources/LookInsideAuthenticatorUIPackageShim"
        ),
        .testTarget(
            name: "LookInsideExtraShimTests",
            dependencies: ["LookInsideExtraSwiftUserInterfaceSupportPackageShim", "LookInsideAuthenticatorPackageShim", "LookInsideAuthenticatorUIPackageShim"],
            path: "Tests/LookInsideExtraShimTests"
        )
    ]
)
