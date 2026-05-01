#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d "${TMPDIR:-/private/tmp}/lookinside-release-sign-test.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

FAKE_BIN="$WORK_DIR/bin"
mkdir -p "$FAKE_BIN"

write_stub_commands() {
	cat >"$FAKE_BIN/security" <<'SH'
#!/bin/bash
printf 'security %s\n' "$*" >> "$SIGN_TEST_LOG"
SH

	cat >"$FAKE_BIN/codesign" <<'SH'
#!/bin/bash
printf 'codesign %s\n' "$*" >> "$SIGN_TEST_LOG"
SH

	cat >"$FAKE_BIN/xcrun" <<'SH'
#!/bin/bash
printf 'xcrun %s\n' "$*" >> "$SIGN_TEST_LOG"
SH

	cat >"$FAKE_BIN/spctl" <<'SH'
#!/bin/bash
printf 'spctl %s\n' "$*" >> "$SIGN_TEST_LOG"
SH

	cat >"$FAKE_BIN/ditto" <<'SH'
#!/bin/bash
printf 'ditto %s\n' "$*" >> "$SIGN_TEST_LOG"
output="${!#}"
mkdir -p "$(dirname "$output")"
printf 'zip\n' > "$output"
SH

	cat >"$FAKE_BIN/file" <<'SH'
#!/bin/bash
case "$*" in
	*NestedMachO*) echo "Mach-O 64-bit executable arm64" ;;
	*) /usr/bin/file "$@" ;;
esac
SH

	chmod +x "$FAKE_BIN/security" "$FAKE_BIN/codesign" "$FAKE_BIN/xcrun" "$FAKE_BIN/spctl" "$FAKE_BIN/ditto" "$FAKE_BIN/file"
}

make_test_app() {
	local app_path="$1"
	mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
	printf '#!/bin/bash\nexit 0\n' > "$app_path/Contents/MacOS/lookinside-auth-server"
	chmod +x "$app_path/Contents/MacOS/lookinside-auth-server"
	printf 'resource\n' > "$app_path/Contents/Resources/readme.txt"
}

run_signing_script() {
	local app_path="$1"
	local output_zip="$2"
	local log_path="$3"

	SIGNING_IDENTITY="Developer ID Application: Test" \
	KEYCHAIN_PATH="$WORK_DIR/test.keychain-db" \
	KEYCHAIN_SECRET="secret" \
	KEYCHAIN_PROFILE="test-profile" \
	SIGN_TEST_LOG="$log_path" \
	PATH="$FAKE_BIN:$PATH" \
		bash "$ROOT_DIR/Scripts/sign-and-notarize-app.sh" \
			--app "$app_path" \
			--output "$output_zip" \
			--skip-notarize
}

assert_contains() {
	local needle="$1"
	local path="$2"
	grep -F -- "$needle" "$path" >/dev/null
}

assert_not_contains() {
	local needle="$1"
	local path="$2"
	if grep -F -- "$needle" "$path" >/dev/null; then
		echo "unexpected log entry: $needle" >&2
		exit 1
	fi
}

write_stub_commands

plain_app="$WORK_DIR/plain/lookinside-auth-server.app"
plain_zip="$WORK_DIR/plain/signed.zip"
plain_log="$WORK_DIR/plain/calls.log"
mkdir -p "$(dirname "$plain_log")"
make_test_app "$plain_app"
run_signing_script "$plain_app" "$plain_zip" "$plain_log"
[[ -f "$plain_zip" ]]
assert_contains "$plain_app/Contents/MacOS/lookinside-auth-server" "$plain_log"
assert_contains "$plain_app" "$plain_log"

nested_app="$WORK_DIR/nested/lookinside-auth-server.app"
nested_zip="$WORK_DIR/nested/signed.zip"
nested_log="$WORK_DIR/nested/calls.log"
mkdir -p "$(dirname "$nested_log")"
make_test_app "$nested_app"
mkdir -p "$nested_app/Contents/Frameworks/Nested.framework"
printf 'nested\n' > "$nested_app/Contents/Frameworks/Nested.framework/NestedMachO"
run_signing_script "$nested_app" "$nested_zip" "$nested_log"
[[ -f "$nested_zip" ]]
assert_contains "$nested_app/Contents/Frameworks/Nested.framework/NestedMachO" "$nested_log"
assert_contains "$nested_app/Contents/Frameworks/Nested.framework" "$nested_log"

resource_app="$WORK_DIR/resource/lookinside-auth-server.app"
resource_zip="$WORK_DIR/resource/signed.zip"
resource_log="$WORK_DIR/resource/calls.log"
resource_bundle="$resource_app/Contents/Resources/swift-nio_NIOPosix.bundle"
mkdir -p "$(dirname "$resource_log")"
make_test_app "$resource_app"
mkdir -p "$resource_bundle/Contents/_CodeSignature" "$resource_bundle/Contents/Resources"
printf 'signature\n' > "$resource_bundle/Contents/_CodeSignature/CodeResources"
printf '{}\n' > "$resource_bundle/Contents/Resources/PrivacyInfo.xcprivacy"
run_signing_script "$resource_app" "$resource_zip" "$resource_log"
[[ -f "$resource_zip" ]]
[[ ! -d "$resource_bundle/Contents/_CodeSignature" ]]
assert_not_contains "$resource_bundle" "$resource_log"

echo "sign-and-notarize-app tests passed"
