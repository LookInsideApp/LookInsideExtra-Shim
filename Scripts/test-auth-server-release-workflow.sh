#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_PATH="$ROOT_DIR/.github/workflows/sign-auth-server.yml"

if grep -n $'\t' "$WORKFLOW_PATH" >/dev/null; then
	echo "workflow contains tab indentation" >&2
	grep -n $'\t' "$WORKFLOW_PATH" >&2
	exit 1
fi

assert_contains() {
	local needle="$1"
	grep -F -- "$needle" "$WORKFLOW_PATH" >/dev/null
}

assert_contains '      - name: Validate Web Publishing Secret'
assert_contains '        with:'
assert_contains 'GH_TOKEN: ${{ github.token }}'
assert_contains 'token: ${{ github.token }}'
assert_contains 'secrets.LOOKINSIDE_WEB_RELEASE_TOKEN || secrets.UPSTREAM_MIRROR_TOKEN'
assert_contains 'LOOKINSIDE_WEB_RELEASE_TOKEN or UPSTREAM_MIRROR_TOKEN secret is required.'
assert_contains 'bash shim/Scripts/sync-auth-server-assets-to-web.sh'

echo "auth server release workflow tests passed"
