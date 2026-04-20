# Agent Instructions

## Release layout

- `storage` is the binary storage release. Every workflow run re-uploads xcframework archives here with `--clobber`.
- Swift Package consumers pin semver tags on this repo. Each successful publish run reads the latest `X.Y.Z` tag, increments patch by 1, and publishes that new version.
- Do not create per-version tags or releases for upstream versions.
- Only GitHub Actions is allowed to write to the `storage` release. Never upload to `storage` from a local machine.

## Git history

- `main` is kept as a single root commit whenever possible. Use squash + force push when consolidating.
- After the initial consolidation, regular workflow commits push normally (no force).
- Semver release tags move forward from the latest published `X.Y.Z` tag.

## Build and Publish workflow

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

## Local development

- Local developers can run the publish script themselves for experimentation, but they must not upload to `storage` from a laptop.
- `swift build` and any test commands are a local-only concern.

## Scripts

- `Scripts/build_and_publish.py` — the only entry point used by the workflow. Keep it minimal: clone → `make package | xcbeautify` → upload → render `Package.swift`.
- `Scripts/render_package_manifest.py` — renders `Package.swift` and the shim `Sources/*PackageShim/Exports.swift` files from in-memory mirror state passed via `--state-path`.
- Do not reintroduce a persistent `Config/mirror-state.json`. State is in-memory per run.

## Upstream sources

- Defined in `Config/upstream-sources.json`.
- Every upstream uses `make package` as its build command and produces an xcframework or xcframework zip.
