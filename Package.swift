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
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideExtraSwiftUserInterfaceSupport.xcframework.zip?sha256=68f35cd71811e435e0ac2cc0d6ed4d9fd385e5102313cb73b071f3d0c2544491",
            checksum: "68f35cd71811e435e0ac2cc0d6ed4d9fd385e5102313cb73b071f3d0c2544491"
        ),
        .target(
            name: "LookInsideExtraSwiftUserInterfaceSupportPackageShim",
            dependencies: ["LookInsideExtraSwiftUserInterfaceSupport"],
            path: "Sources/LookInsideExtraSwiftUserInterfaceSupportPackageShim"
        ),
        .binaryTarget(
            name: "LookInsideAuthenticator",
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideAuthenticator.xcframework.zip?sha256=d0931a4cab2b075df610a5d9126c669ffef9fece33c5447754bd75c2761f8cf5",
            checksum: "d0931a4cab2b075df610a5d9126c669ffef9fece33c5447754bd75c2761f8cf5"
        ),
        .target(
            name: "LookInsideAuthenticatorPackageShim",
            dependencies: ["LookInsideAuthenticator"],
            path: "Sources/LookInsideAuthenticatorPackageShim"
        ),
        .binaryTarget(
            name: "LookInsideAuthenticatorUI",
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideAuthenticatorUI.xcframework.zip?sha256=af259186615ee898ed222088134c8431e33d2ad2a0dd918b054e22af9a6c819b",
            checksum: "af259186615ee898ed222088134c8431e33d2ad2a0dd918b054e22af9a6c819b"
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
