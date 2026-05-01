#!/bin/bash

set -euo pipefail

WEB_DIR=""
ASSET_ZIP=""
MAX_STATIC_ASSET_BYTES="${MAX_STATIC_ASSET_BYTES:-25165824}"
EXPECTED_ASSET_NAME="lookinside-auth-server.app.zip"

usage() {
	cat <<'EOF'
Usage: bash Scripts/sync-auth-server-assets-to-web.sh --web-dir <path> --asset <path>

Options:
  --web-dir <path>   Checkout path of LookInside-Web.
  --asset <path>     Signed Auth Server zip. Matching .sha256 and .version files must sit next to it.
  --help, -h         Show this help.
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
[[ -d "$WEB_DIR/public" ]] || fail "Web public directory not found: $WEB_DIR/public"
[[ -f "$ASSET_ZIP" ]] || fail "Auth Server zip not found: $ASSET_ZIP"

asset_name="$(basename "$ASSET_ZIP")"
[[ "$asset_name" == "$EXPECTED_ASSET_NAME" ]] || fail "Auth Server asset must be named $EXPECTED_ASSET_NAME because the Host app downloads that fixed path."

checksum_file="${ASSET_ZIP}.sha256"
version_file="${ASSET_ZIP}.version"
[[ -f "$checksum_file" ]] || fail "Checksum file not found: $checksum_file"
[[ -f "$version_file" ]] || fail "Version marker not found: $version_file"

asset_size="$(file_size "$ASSET_ZIP")"
if [[ "$asset_size" -gt "$MAX_STATIC_ASSET_BYTES" ]]; then
	fail "Auth Server zip is ${asset_size} bytes, above the ${MAX_STATIC_ASSET_BYTES} byte static-asset gate. Move helper downloads to R2 before publishing this release."
fi

dest_dir="$WEB_DIR/public/downloads/auth-server"
mkdir -p "$dest_dir"

cp "$ASSET_ZIP" "$dest_dir/$EXPECTED_ASSET_NAME"
cp "$checksum_file" "$dest_dir/$EXPECTED_ASSET_NAME.sha256"
cp "$version_file" "$dest_dir/$EXPECTED_ASSET_NAME.version"
