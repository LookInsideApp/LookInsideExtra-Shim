# Agent Instructions

## Repo Scope

This repo has two independent responsibilities:

1. Mirror the remaining upstream xcframework(s) declared in `Config/upstream-sources.json` as Swift Package binary targets on the `storage` release.
2. Re-sign and notarize the LookInside auth server `.app` produced by the auth helper source repo, and publish the signed zip on the `storage` release.

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

## Build and Publish Auth Server workflow

- Workflow file: `.github/workflows/sign-auth-server.yml`, named **Build and Publish Auth Server**.
- Trigger: `workflow_dispatch`. Inputs: `source_ref` (git ref of the auth helper source repo, default `main`), `output_asset` (default `lookinside-auth-server.app.zip`).
- The authenticator repo contains source only. It has no workflows. All packaging, signing, notarization, and publishing for the auth server live here.
- Steps:
  1. Check out the shim repo and the authenticator source (private, cloned with `UPSTREAM_MIRROR_TOKEN`).
  2. Install `mise` via Homebrew, then `mise install` inside the authenticator checkout to get the tuist version pinned in `mise.toml`.
  3. Compute a UTC build timestamp `YYYY.MMDD.HHMMSS` and export it as `MARKETING_VERSION`. This flows into the helper's `CFBundleShortVersionString` / `CFBundleVersion` and is advertised on `health.ping` as `server_version`.
  4. Run `make app` with that `MARKETING_VERSION` in env to produce `lookinside-auth-server.app.zip` at the authenticator repo root.
  5. `ditto -x -k` to unpack the `.app` bundle.
  6. Restore the signing keychain with `Scripts/setup-ci-keychain.sh`.
  7. Run `Scripts/sign-and-notarize-app.sh` to codesign the bundle and nested executables, notarize with notarytool, staple, and re-zip.
  8. Ensure the `storage` release exists, upload the signed zip, its `.sha256` checksum, and a `.version` plain-text asset (containing just the timestamp) with `--clobber`. The `.version` file is the source of truth for LookInside's stale-cache detection — host fetches it and compares against the installed helper's `CFBundleShortVersionString`.
- The workflow must **not** run `swift build`, `swift test`, or resolve SwiftPM dependencies in the shim package. GitHub runners have slow downloads, so CI in this repo must stay clear of SwiftPM fetch/resolve work against `Package.swift`. Running tuist and xcodebuild inside the authenticator checkout is expected.

## Required CI secrets

- `UPSTREAM_MIRROR_TOKEN`: PAT used to clone upstream repos and download private release assets.
- `UPSTREAM_SERVER_REPO_URL`: clone URL of the private LookInsideServer source repo (referenced by `Config/upstream-sources.json` via `repositoryEnv`). Kept in a secret so the public repo never reveals the source URL.
- `AUTH_SOURCE_REPO`: `owner/name` of the private auth helper source repo. Consumed by the Sign Auth Server workflow's checkout step.
- `WEB_TARGET_REPO`: `owner/name` of the private website repo that receives the signed Auth Server asset. Consumed by the Sign Auth Server workflow's checkout step.
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
