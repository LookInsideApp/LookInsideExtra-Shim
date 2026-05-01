#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_PATH="$ROOT_DIR/.github/workflows/sign-auth-server.yml"

assert_contains() {
	local needle="$1"
	grep -F -- "$needle" "$WORKFLOW_PATH" >/dev/null
}

assert_contains 'secrets.LOOKINSIDE_WEB_RELEASE_TOKEN || secrets.UPSTREAM_MIRROR_TOKEN'
assert_contains 'LOOKINSIDE_WEB_RELEASE_TOKEN or UPSTREAM_MIRROR_TOKEN secret is required.'
assert_contains 'bash shim/Scripts/sync-auth-server-assets-to-web.sh'

echo "auth server release workflow tests passed"
