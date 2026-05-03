# LookInside-Release

Two responsibilities, one repo:

1. **SwiftPM mirror** for the prebuilt LookInside XCFrameworks. Consumers add this package and get binary targets pinned by checksum.
2. **Auth helper signing pipeline.** Builds the LookInside auth helper source, code-signs it, notarizes it, and publishes the helper `.app` zip.

Website · [lookinside-app.com](https://lookinside-app.com)

---

## How to consume the SwiftPM mirror

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
                name: "LookInsideServerStatic",
                package: "LookInside-Release"
            ),
        ]
    ),
]
```

Each library product points directly at a `.binaryTarget` whose URL lives on the same semver GitHub Release tag as the package version.

Currently mirrored upstreams (see [`Config/upstream-sources.json`](Config/upstream-sources.json)):

| Module                    | Linkage |
| ------------------------- | ------- |
| `LookInsideServerStatic`  | static  |
| `LookInsideServerDynamic` | dynamic |

---

## Release layout

- Swift Package consumers pin semver tags (`X.Y.Z`) on this repo.
- Each successful **Build and Publish** run reads the latest `X.Y.Z`, increments patch by 1, builds the binary assets, renders `Package.swift` with URLs for that new tag, commits the manifest, pushes `main` plus the tag, then uploads the assets to that tag's GitHub Release.
- Asset names stay stable across releases, for example `LookInsideServer.xcframework.zip` and `LookInsideServerDynamic.xcframework.zip`; SwiftPM pins exact bytes via the checksum in `Package.swift`.

---

## Pipelines

### Build and Publish — XCFramework mirror

`.github/workflows/build-and-publish.yml`

1. Clones each upstream listed in `Config/upstream-sources.json`.
2. Builds it via `make package | xcbeautify`.
3. Computes the resulting xcframework zip checksums.
4. Regenerates `Package.swift` with URLs under the next semver release tag.
5. Commits the manifest, pushes `main` and the tag, then uploads the xcframework zips to that release.

Run `swift test` against the rendered manifest before publishing or immediately after the release tag is cut to verify binary imports.

### Build and Publish Auth Server

`.github/workflows/sign-auth-server.yml` (manual `workflow_dispatch`)

The auth helper source repo holds source only. All packaging, signing, notarization, and publishing for the helper happens here:

1. Check out this repo and the authenticator source at the requested ref.
2. Install Tuist via `mise`.
3. Stamp a UTC build timestamp `YYYY.MMDD.HHMMSS` as `MARKETING_VERSION` (flows into `CFBundleShortVersionString` / `CFBundleVersion` and gets advertised on `health.ping`).
4. Run `make app` to produce `lookinside-auth-server.app.zip`.
5. Restore the signing keychain, codesign and notarize via `notarytool`, staple, and re-zip.
6. Upload the signed zip, its `.sha256`, and a `.version` plain-text asset to `storage`. The host app reads `.version` to detect a stale local helper.

CI in this repo does not run `swift build` / `swift test` during release creation because the release assets do not exist until after the manifest commit is tagged and uploaded.

---

## Local development

```bash
Scripts/build_and_publish.py --release-tag 0.1.5  # exercise the mirror flow locally
Scripts/sign-and-notarize-app.sh      # sign a .app bundle locally
```

Local runs build assets into `build/release-assets/` and render `Package.swift`; they do not upload GitHub Release assets.

`swift build` and any local tests of `Package.swift` are a development-only concern.

---

## License

Source-available. Release binaries inherit their upstream license.
