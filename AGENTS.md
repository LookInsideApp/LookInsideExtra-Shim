# Agent Instructions

## Repo Scope

This repo has two independent responsibilities:

1. Mirror the remaining upstream xcframework(s) declared in `Config/upstream-sources.json` as Swift Package binary targets on the `storage` release.
2. Re-sign and notarize the LookInside auth server `.app` produced by the `LookInsideAuthenticator` repo, and publish the signed zip on the `storage` release.

The authenticator and authenticator-ui xcframeworks are retired. The auth server now ships as a standalone notarized `.app`, signed in this repo.

## Release layout

- `storage` is the binary storage release. Every workflow run re-uploads artifacts here with `--clobber`.
- Swift Package consumers pin semver tags on this repo. Each successful **Build and Publish** run reads the latest `X.Y.Z` tag, increments patch by 1, and publishes that new version.
- Do not create per-version tags or releases for upstream versions.
- Only GitHub Actions is allowed to write to the `storage` release. Never upload to `storage` from a local machine.

## Git history

- `main` is kept as a single root commit whenever possible. Use squash + force push when consolidating.
- After the initial consolidation, regular workflow commits push normally (no force).
- Semver release tags move forward from the latest published `X.Y.Z` tag.

## Build and Publish workflow (xcframework mirror)

- Workflow file: `.github/workflows/build-and-publish.yml`, named **Build and Publish**.
- Runs on `macos-latest` using the `UPSTREAM_MIRROR_TOKEN` secret for cloning private upstream repos.
- Each run always rebuilds. No state comparison, no skip-if-already-built logic.
- The workflow is only allowed to:
  1. Clone each upstream repo listed in `Config/upstream-sources.json`.
  2. Build the xcframework via `make package` piped through `xcbeautify`.
  3. Zip the xcframework if needed and upload it to the `storage` release with `--clobber`.
  4. Regenerate `Package.swift` with the fresh checksums and commit the change to `main`.
  5. Publish the next patch semver tag/release for Swift Package consumers after the `main` update is available.
- The workflow must **not** run `swift build`, `swift test`, or any other verification against this repo's package in CI.

## Sign Auth Server workflow

- Workflow file: `.github/workflows/sign-auth-server.yml`, named **Sign Auth Server**.
- Trigger: `workflow_dispatch`. Inputs: upstream repo, upstream tag, upstream asset name, signed output asset name. Defaults target `LookInsideApp/LookInsideAuthenticator` and `lookinside-auth-server.app.zip`.
- Steps:
  1. Download the unsigned `.app.zip` from the upstream release using `gh`.
  2. `ditto -x -k` to unpack the `.app` bundle.
  3. Restore the signing keychain with `Scripts/setup-ci-keychain.sh`.
  4. Run `Scripts/sign-and-notarize-app.sh` to codesign the bundle and nested executables, notarize with notarytool, staple, and re-zip.
  5. Ensure the `storage` release exists, upload the signed zip plus a `.sha256` checksum with `--clobber`.
- The workflow must **not** build source from the upstream repo. It only re-signs what was published.
- The workflow must **not** run `swift build`, `swift test`, or resolve SwiftPM dependencies. GitHub runners have slow downloads, so all CI jobs in this repo must stay clear of SwiftPM fetch/resolve work.

## Required CI secrets

- `UPSTREAM_MIRROR_TOKEN`: PAT used to clone upstream repos and download private release assets.
- `KEYCHAIN_CONTENT_GZIP`: base64(gzip(keychain db)) containing the Developer ID Application certificate and a saved notarytool profile.
- `KEYCHAIN_SECRET`: unlock password for the restored keychain.

## Local development

- Local developers can run `Scripts/build_and_publish.py` for experimentation, but must not upload to `storage` from a laptop.
- `Scripts/sign-and-notarize-app.sh` can be invoked locally against a downloaded unsigned `.app` if `SIGNING_IDENTITY`, `KEYCHAIN_PATH`, `KEYCHAIN_SECRET`, and `KEYCHAIN_PROFILE` are set, but do not upload the result to `storage`.
- `swift build` and any test commands are a local-only concern.

## Scripts

- `Scripts/build_and_publish.py` — xcframework mirror entry point used by **Build and Publish**. Keep it minimal: clone → `make package | xcbeautify` → upload → render `Package.swift`.
- `Scripts/render_package_manifest.py` — renders `Package.swift` and the shim `Sources/*PackageShim/Exports.swift` files from in-memory mirror state passed via `--state-path`.
- `Scripts/setup-ci-keychain.sh` — restores the signing keychain from CI secrets, exports keychain/signing identity/notarytool profile outputs.
- `Scripts/sign-and-notarize-app.sh` — signs a `.app` bundle, notarizes via notarytool, staples, and writes a final zip.
- Do not reintroduce a persistent `Config/mirror-state.json`. State is in-memory per run.

## Upstream sources

- Defined in `Config/upstream-sources.json`.
- Every upstream listed here uses `make package` as its build command and produces an xcframework or xcframework zip.
- The auth server is not an upstream source in that sense — it is handled by the Sign Auth Server workflow and is not listed in this file.
