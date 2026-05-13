# LookInside-Release

This repo gives your app the LookInside debug server. Add it to the app you want to inspect, then open LookInside on your Mac.

Website: [lookinside-app.com](https://lookinside-app.com)

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

For Release builds, open your app target's Build Settings and set **Excluded Source File Names** to:

```text
LookInsideServer*
```

Keep direct `LookInsideServer` API calls inside Debug-only code paths.

## CocoaPods

```ruby
target "YourApp" do
  pod "LookInsideServer",
      :git => "https://github.com/LookInsideApp/LookInside-Release.git",
      :tag => "X.Y.Z",
      :configurations => ["Debug"]
end
```

The CocoaPods snippet scopes `LookInsideServer` to Debug builds through `:configurations => ["Debug"]`.

## Manual XCFramework

Download and unzip `LookInsideServer.xcframework.zip` from the latest release, then drag `LookInsideServer.xcframework` into your Xcode project. In your debug target's **General** tab → **Frameworks, Libraries, and Embedded Content**, set it to **Embed & Sign**.

For Release builds, open your app target's Build Settings and set **Excluded Source File Names** to:

```text
LookInsideServer*
```

## Product

| Name | What it does |
| ---- | ------------ |
| `LookInsideServer` | Starts the local debug server inside your app. |

Use the latest semver tag from this repository.

## License

Release binaries inherit their upstream license.
