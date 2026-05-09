# LookInside-Release

Prebuilt LookInside binaries for Swift Package Manager and CocoaPods.

Website · [lookinside-app.com](https://lookinside-app.com)

---

## Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/LookInsideApp/LookInside-Release.git", from: "X.Y.Z"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(
                name: "LookInsideServer",
                package: "LookInside-Release"
            ),
        ]
    ),
]
```

The `LookInsideServer` product points at a dynamic `.binaryTarget`. `dyld` runs the framework's module initializers when it loads the image, so the server boots automatically.

## CocoaPods

Use the GitHub tag directly from your `Podfile`:

```ruby
target "YourApp" do
  pod "LookInsideServer",
      :git => "https://github.com/LookInsideApp/LookInside-Release.git",
      :tag => "0.2.1",
      :configurations => ["Debug"]
end
```

Use a published semver tag. The podspec downloads the matching `LookInsideServer.xcframework.zip`, verifies its SHA-256 checksum, and vendors the extracted XCFramework.

Available products:

| Module             | Linkage |
| ------------------ | ------- |
| `LookInsideServer` | dynamic |

---

## Versioning

Use the latest semver tag from this repository. SwiftPM and CocoaPods both resolve the exact binary archive referenced by the tag metadata.

---

## License

Source-available. Release binaries inherit their upstream license.
