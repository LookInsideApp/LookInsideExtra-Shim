#!/bin/bash

set -euo pipefail

WEB_DIR=""
ASSET_ZIP=""
ASSET_URL=""
EXPECTED_ASSET_NAME="lookinside-auth-server.app.zip"
MANIFEST_ASSET_ID="lookinside-auth-server"

usage() {
	cat <<'EOF'
Usage: bash Scripts/sync-auth-server-assets-to-web.sh --web-dir <path> --asset <path> --url <download-url>

Options:
  --web-dir <path>   Checkout path of the website target repo.
  --asset <path>     Signed Auth Server zip. Matching .sha256 and .version files must sit next to it.
  --url <url>        GitHub Release download URL for the signed zip (consumed by web prebuild fetcher).
  --help, -h         Show this help.

Behavior:
  - Copies the .sha256 and .version sidecars next to public/downloads/auth-server/ (small text files,
    needed by the host app's stale-cache check).
  - Updates public/downloads/manifest.json to point the lookinside-auth-server asset at <url>
    with the freshly computed sha256 and size. The zip itself is NOT copied into the web repo —
    the website's prebuild step fetches it from <url> at build time.
EOF
}

fail() {
	echo "Error: $*" >&2
	exit 1
}

file_size() {
	local path="$1"
	if stat -f%z "$path" >/dev/null 2>&1; then
		stat -f%z "$path"
	else
		stat -c%s "$path"
	fi
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--web-dir)
			WEB_DIR="${2:-}"
			shift 2
			;;
		--asset)
			ASSET_ZIP="${2:-}"
			shift 2
			;;
		--url)
			ASSET_URL="${2:-}"
			shift 2
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

parse_args "$@"

[[ -n "$WEB_DIR" ]] || fail "--web-dir is required."
[[ -n "$ASSET_ZIP" ]] || fail "--asset is required."
[[ -n "$ASSET_URL" ]] || fail "--url is required."
[[ -d "$WEB_DIR/public" ]] || fail "Web public directory not found: $WEB_DIR/public"
[[ -f "$ASSET_ZIP" ]] || fail "Auth Server zip not found: $ASSET_ZIP"

asset_name="$(basename "$ASSET_ZIP")"
[[ "$asset_name" == "$EXPECTED_ASSET_NAME" ]] || fail "Auth Server asset must be named $EXPECTED_ASSET_NAME because the Host app downloads that fixed path."

checksum_file="${ASSET_ZIP}.sha256"
version_file="${ASSET_ZIP}.version"
[[ -f "$checksum_file" ]] || fail "Checksum file not found: $checksum_file"
[[ -f "$version_file" ]] || fail "Version marker not found: $version_file"

asset_size="$(file_size "$ASSET_ZIP")"
asset_sha256="$(awk '{ print $1; exit }' "$checksum_file")"
asset_version="$(tr -d '[:space:]' <"$version_file")"
[[ -n "$asset_sha256" ]] || fail "Could not parse sha256 from $checksum_file."
[[ -n "$asset_version" ]] || fail "Version marker $version_file is empty."

dest_dir="$WEB_DIR/public/downloads/auth-server"
mkdir -p "$dest_dir"

cp "$checksum_file" "$dest_dir/$EXPECTED_ASSET_NAME.sha256"
cp "$version_file" "$dest_dir/$EXPECTED_ASSET_NAME.version"

manifest_path="$WEB_DIR/public/downloads/manifest.json"
[[ -f "$manifest_path" ]] || fail "Web manifest not found: $manifest_path"

node "$WEB_DIR/scripts/update-manifest.mjs" \
	--manifest "$manifest_path" \
	--id "$MANIFEST_ASSET_ID" \
	--destination "public/downloads/auth-server/$EXPECTED_ASSET_NAME" \
	--version "$asset_version" \
	--tag "storage" \
	--size "$asset_size" \
	--sha256 "$asset_sha256" \
	--url "$ASSET_URL"
