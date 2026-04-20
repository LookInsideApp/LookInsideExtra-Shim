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
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideExtraSwiftUserInterfaceSupport.xcframework.zip?sha256=458f5fa2ca9cf98589d5f1e9f75ec2b044f057fa07e7741553141dd5f4da7a65",
            checksum: "458f5fa2ca9cf98589d5f1e9f75ec2b044f057fa07e7741553141dd5f4da7a65"
        ),
        .target(
            name: "LookInsideExtraSwiftUserInterfaceSupportPackageShim",
            dependencies: ["LookInsideExtraSwiftUserInterfaceSupport"],
            path: "Sources/LookInsideExtraSwiftUserInterfaceSupportPackageShim"
        ),
        .binaryTarget(
            name: "LookInsideAuthenticator",
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideAuthenticator.xcframework.zip?sha256=1b636a026131ad143a4f19f28367af951c2fe2a44bc1436f7cf388d542aeb559",
            checksum: "1b636a026131ad143a4f19f28367af951c2fe2a44bc1436f7cf388d542aeb559"
        ),
        .target(
            name: "LookInsideAuthenticatorPackageShim",
            dependencies: ["LookInsideAuthenticator"],
            path: "Sources/LookInsideAuthenticatorPackageShim"
        ),
        .binaryTarget(
            name: "LookInsideAuthenticatorUI",
            url: "https://github.com/LookInsideApp/LookInsideExtra-Shim/releases/download/storage/LookInsideAuthenticatorUI.xcframework.zip?sha256=340a7ec3cc65dcc16a778db4865e88e4e98c5d3490272ee1b8effd74b5992710",
            checksum: "340a7ec3cc65dcc16a778db4865e88e4e98c5d3490272ee1b8effd74b5992710"
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
