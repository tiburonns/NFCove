#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
temp_dir="$(mktemp -d /tmp/nfcove-core-tests.XXXXXX)"
test_binary="$temp_dir/nfcove-core-tests"
trap 'rm -rf "$temp_dir"' EXIT

xcrun swiftc -parse-as-library \
  "$repo_root/NFCove/Models/NFCRecordModels.swift" \
  "$repo_root/NFCove/App/LibraryStore.swift" \
  "$repo_root/Tests/CoreLogicIntegration.swift" \
  -o "$test_binary"

"$test_binary"
