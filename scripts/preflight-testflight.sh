#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "== NFCove TestFlight preflight =="
xcodebuild -version
swift --version
plutil -lint NFCove/Resources/Info.plist
plutil -lint NFCove/Resources/NFCove.entitlements
plutil -lint NFCove/Resources/PrivacyInfo.xcprivacy
python3 Tests/validate-release-contract.py
zsh Tests/run-core-tests.sh

xcodebuild \
  -project NFCove.xcodeproj \
  -scheme NFCove \
  -configuration Release \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
  build

chmod +x scripts/build-unsigned-ipa.sh
scripts/build-unsigned-ipa.sh

echo
echo "PASS: source/tests/Release device build completed."
echo "Next: enable Near Field Communication Tag Reading for com.tiburonns.NFCove,"
echo "download an App Store distribution profile containing TAG, then Archive/Validate in Xcode."
