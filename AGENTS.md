# Agent Instructions

## Release layout

- Exactly two tags/releases exist on this repo and nothing else:
  - `storage` — binary storage release. Every workflow run re-uploads xcframework archives here with `--clobber`.
  - `0.1.0` — the Swift Package release tag consumers pin to.
- Do not create per-version tags or releases for upstream versions.
- Only GitHub Actions is allowed to write to the `storage` release. Never upload to `storage` from a local machine.

## Git history

- `main` is kept as a single root commit whenever possible. Use squash + force push when consolidating.
- After the initial consolidation, regular workflow commits push normally (no force).
- The `0.1.0` tag may be force-moved when the root commit is rewritten; otherwise leave it alone.

## Build and Publish workflow

- Workflow file: `.github/workflows/build-and-publish.yml`, named **Build and Publish**.
- Runs on `macos-latest` using the `UPSTREAM_MIRROR_TOKEN` secret for cloning private upstream repos.
- Each run always rebuilds. No state comparison, no skip-if-already-built logic.
- The workflow is only allowed to:
  1. Clone each upstream repo listed in `Config/upstream-sources.json`.
  2. Build the xcframework via `make package` piped through `xcbeautify`.
  3. Zip the xcframework if needed and upload it to the `storage` release with `--clobber`.
  4. Regenerate `Package.swift` with the fresh checksums and commit the change to `main`.
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
