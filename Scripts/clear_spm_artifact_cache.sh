#!/bin/zsh

set -euo pipefail

cache_paths=(
	"$HOME/Library/Caches/org.swift.swiftpm"
	"$HOME/Library/org.swift.swiftpm"
	"$HOME/.swiftpm/cache"
)

for cache_path in "${cache_paths[@]}"; do
	if [[ -e "$cache_path" ]]; then
		rm -rf "$cache_path"
	fi
done

swift package reset
