# LookInside-Release

Two responsibilities, one repo:

1. **SwiftPM mirror** for the prebuilt LookInside XCFrameworks. Consumers add this package and get binary targets pinned by checksum.
2. **Auth helper signing pipeline.** Builds the [LookInside-Auth](https://github.com/LookInsideApp/LookInside-Auth) source, code-signs it, notarizes it, and publishes the helper `.app` zip.

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

Each library is a thin shim around a `.binaryTarget` whose URL points at the `storage` GitHub Release on this repo. URLs include a checksum query so SwiftPM caches stay clean across rebuilds.

Currently mirrored upstreams (see [`Config/upstream-sources.json`](Config/upstream-sources.json)):

| Module                    | Source repo                                                             | Linkage |
| ------------------------- | ----------------------------------------------------------------------- | ------- |
| `LookInsideServerStatic`  | [LookInside-Server](https://github.com/LookInsideApp/LookInside-Server) | static  |
| `LookInsideServerDynamic` | [LookInside-Server](https://github.com/LookInsideApp/LookInside-Server) | dynamic |

---

## Release layout

- The `storage` GitHub Release on this repo is the binary storage location. Server artifacts are uploaded with checksum-bearing file names so older semver tags keep resolving to the exact bytes they pinned.
- Swift Package consumers pin semver tags (`X.Y.Z`) on this repo. Each successful **Build and Publish** run reads the latest `X.Y.Z`, increments patch by 1, and publishes the new tag.
- Only GitHub Actions writes to `storage`. Local laptops never upload there.

---

## Pipelines

### Build and Publish — XCFramework mirror

`.github/workflows/build-and-publish.yml`

1. Clones each upstream listed in `Config/upstream-sources.json`.
2. Builds it via `make package | xcbeautify`.
3. Uploads the resulting xcframework zip to `storage` with `--clobber`.
4. Regenerates `Package.swift` with fresh checksums and commits to `main`.
5. Publishes the next patch semver tag for SwiftPM consumers.

Run `swift test` against the rendered manifest before publishing or immediately after the release tag is cut to verify binary imports.

### Build and Publish Auth Server

`.github/workflows/sign-auth-server.yml` (manual `workflow_dispatch`)

The [LookInside-Auth](https://github.com/LookInsideApp/LookInside-Auth) repo holds source only. All packaging, signing, notarization, and publishing for the helper happens here:

1. Check out this repo and the authenticator source at the requested ref.
2. Install Tuist via `mise`.
3. Stamp a UTC build timestamp `YYYY.MMDD.HHMMSS` as `MARKETING_VERSION` (flows into `CFBundleShortVersionString` / `CFBundleVersion` and gets advertised on `health.ping`).
4. Run `make app` to produce `lookinside-auth-server.app.zip`.
5. Restore the signing keychain, codesign and notarize via `notarytool`, staple, and re-zip.
6. Upload the signed zip, its `.sha256`, and a `.version` plain-text asset to `storage`. The host app reads `.version` to detect a stale local helper.

CI in this repo never runs `swift build` / `swift test` — the SwiftPM checksum machinery does not need it, and GitHub-hosted runners have slow downloads.

---

## Local development

```bash
Scripts/build_and_publish.py          # exercise the mirror flow locally
Scripts/sign-and-notarize-app.sh      # sign a .app bundle locally
```

Local runs must not upload to `storage` — that path is reserved for CI.

`swift build` and any local tests of `Package.swift` are a development-only concern.

---

## License

Source-available. The binaries on the `storage` release inherit their upstream license.
