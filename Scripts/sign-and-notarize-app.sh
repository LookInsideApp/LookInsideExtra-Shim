#!/bin/bash

set -euo pipefail

APP_PATH=""
OUTPUT_ZIP=""
ENTITLEMENTS_PATH=""
SKIP_NOTARIZE=false

usage() {
	cat <<'EOF'
Usage: bash Scripts/sign-and-notarize-app.sh --app <path> --output <zip> [options]

Options:
  --app <path>              Path to the .app bundle to sign (required).
  --output <zip>            Path of the final signed, notarized, stapled zip (required).
  --entitlements <path>     Optional entitlements plist. If omitted, codesign uses defaults.
  --skip-notarize           Sign only. Skip notarization and stapling.
  --help, -h                Show this help.

Environment required for signing:
  SIGNING_IDENTITY          Developer ID Application hash or common name.
  KEYCHAIN_PATH             Path to the restored signing keychain.
  KEYCHAIN_SECRET           Password for the signing keychain.
  KEYCHAIN_PROFILE          notarytool keychain profile name (unless --skip-notarize).
EOF
}

log() {
	echo "==> $*"
}

fail() {
	echo "Error: $*" >&2
	exit 1
}

require_command() {
	command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--app)
			APP_PATH="${2:-}"
			shift 2
			;;
		--output)
			OUTPUT_ZIP="${2:-}"
			shift 2
			;;
		--entitlements)
			ENTITLEMENTS_PATH="${2:-}"
			shift 2
			;;
		--skip-notarize)
			SKIP_NOTARIZE=true
			shift
			;;
		--help | -h)
			usage
			exit 0
			;;
		*)
			fail "Unknown option: $1"
			;;
		esac
	done
}

ensure_signing_env() {
	[[ -n "${SIGNING_IDENTITY:-}" ]] || fail "SIGNING_IDENTITY is required."
	[[ -n "${KEYCHAIN_PATH:-}" ]] || fail "KEYCHAIN_PATH is required."
	[[ -n "${KEYCHAIN_SECRET:-}" ]] || fail "KEYCHAIN_SECRET is required."
	if [[ "$SKIP_NOTARIZE" != "true" ]]; then
		[[ -n "${KEYCHAIN_PROFILE:-}" ]] || fail "KEYCHAIN_PROFILE is required unless --skip-notarize."
	fi
}

unlock_keychain() {
	log "Unlocking signing keychain"
	security default-keychain -d user -s "$KEYCHAIN_PATH"
	security unlock-keychain -p "$KEYCHAIN_SECRET" "$KEYCHAIN_PATH"
	security set-keychain-settings -t 3600 -u "$KEYCHAIN_PATH"
	security set-key-partition-list \
		-S apple-tool:,apple:,codesign: \
		-s \
		-k "$KEYCHAIN_SECRET" \
		"$KEYCHAIN_PATH"
}

sign_app_bundle() {
	local executables=()
	while IFS= read -r executable; do
		executables+=("$executable")
	done < <(find "$APP_PATH/Contents/MacOS" -maxdepth 1 -type f -perm -u+x)

	[[ "${#executables[@]}" -ge 1 ]] || fail "No executables found under $APP_PATH/Contents/MacOS."

	log "Signing ${#executables[@]} nested executable(s)"
	for executable in "${executables[@]}"; do
		chmod 755 "$executable"
		codesign \
			--sign "$SIGNING_IDENTITY" \
			--options runtime \
			--timestamp \
			--force \
			--verbose=2 \
			"$executable"
	done

	log "Signing app bundle"
	local codesign_args=(
		--sign "$SIGNING_IDENTITY"
		--options runtime
		--timestamp
		--force
		--verbose=2
	)
	if [[ -n "$ENTITLEMENTS_PATH" ]]; then
		[[ -f "$ENTITLEMENTS_PATH" ]] || fail "Entitlements file not found: $ENTITLEMENTS_PATH"
		codesign_args+=(--entitlements "$ENTITLEMENTS_PATH")
	fi
	codesign_args+=("$APP_PATH")

	codesign "${codesign_args[@]}"

	log "Verifying app signature"
	codesign --verify --deep --strict --verbose=2 "$APP_PATH"
}

zip_app() {
	rm -f "$OUTPUT_ZIP"
	mkdir -p "$(dirname "$OUTPUT_ZIP")"
	ditto -c -k --keepParent "$APP_PATH" "$OUTPUT_ZIP"
}

notarize_and_staple() {
	if [[ "$SKIP_NOTARIZE" == "true" ]]; then
		log "Skipping notarization and stapling"
		return
	fi

	log "Submitting app for notarization"
	xcrun notarytool submit "$OUTPUT_ZIP" \
		--keychain-profile "$KEYCHAIN_PROFILE" \
		--wait

	log "Stapling notarization ticket"
	xcrun stapler staple "$APP_PATH"

	log "Re-zipping stapled app"
	rm -f "$OUTPUT_ZIP"
	ditto -c -k --keepParent "$APP_PATH" "$OUTPUT_ZIP"

	log "Assessing stapled app with spctl"
	spctl --assess --type execute --verbose=4 "$APP_PATH"
}

parse_args "$@"

[[ -n "$APP_PATH" ]] || {
	usage
	fail "--app is required."
}
[[ -n "$OUTPUT_ZIP" ]] || {
	usage
	fail "--output is required."
}
[[ -d "$APP_PATH" ]] || fail "App bundle not found: $APP_PATH"

require_command codesign
require_command xcrun
require_command ditto
require_command security
require_command spctl

ensure_signing_env
unlock_keychain
sign_app_bundle
zip_app
notarize_and_staple

log "Done"
log "Signed app: $APP_PATH"
log "Release zip: $OUTPUT_ZIP"
