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

## CocoaPods

```ruby
target "YourApp" do
  pod "LookInsideServer",
      :git => "https://github.com/LookInsideApp/LookInside-Release.git",
      :tag => "X.Y.Z",
      :configurations => ["Debug"]
end
```

## Product

| Name | What it does |
| ---- | ------------ |
| `LookInsideServer` | Starts the local debug server inside your app. |

Use the latest semver tag from this repository.

## License

Release binaries inherit their upstream license.
