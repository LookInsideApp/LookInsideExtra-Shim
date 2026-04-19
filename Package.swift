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
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideExtraSwiftUserInterfaceSupport.xcframework.zip?sha256=e864783e40dec462ace9ae293fa4c1d1bc2d779be2dedb6638c5a7a956fe7f01",
            checksum: "e864783e40dec462ace9ae293fa4c1d1bc2d779be2dedb6638c5a7a956fe7f01"
        ),
        .target(
            name: "LookInsideExtraSwiftUserInterfaceSupportPackageShim",
            dependencies: ["LookInsideExtraSwiftUserInterfaceSupport"],
            path: "Sources/LookInsideExtraSwiftUserInterfaceSupportPackageShim"
        ),
        .binaryTarget(
            name: "LookInsideAuthenticator",
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideAuthenticator.xcframework.zip?sha256=13a585d1b5030d081b9b52d73775a38ef9e5eddd7e1d30aa70ac1b5ed181b8dc",
            checksum: "13a585d1b5030d081b9b52d73775a38ef9e5eddd7e1d30aa70ac1b5ed181b8dc"
        ),
        .target(
            name: "LookInsideAuthenticatorPackageShim",
            dependencies: ["LookInsideAuthenticator"],
            path: "Sources/LookInsideAuthenticatorPackageShim"
        ),
        .binaryTarget(
            name: "LookInsideAuthenticatorUI",
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideAuthenticatorUI.xcframework.zip?sha256=dc2a4a07ddec40e775d9aeb006e359a8da1fa2dfb44b176d6b49fa8466be3194",
            checksum: "dc2a4a07ddec40e775d9aeb006e359a8da1fa2dfb44b176d6b49fa8466be3194"
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
