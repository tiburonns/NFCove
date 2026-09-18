#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
APP_PATH="$DERIVED_DATA/Build/Products/Release-iphoneos/NFCove.app"
IPA_PATH="$BUILD_DIR/NFCove-unsigned.ipa"

rm -rf "$DERIVED_DATA" "$BUILD_DIR/Payload" "$IPA_PATH"
mkdir -p "$BUILD_DIR"

xcodebuild   -project "$ROOT_DIR/NFCove.xcodeproj"   -scheme NFCove   -configuration Release   -destination "generic/platform=iOS"   -derivedDataPath "$DERIVED_DATA"   CODE_SIGNING_ALLOWED=NO   CODE_SIGNING_REQUIRED=NO   build

if [[ ! -d "$APP_PATH" ]]; then
  echo "NFCove.app was not produced at $APP_PATH" >&2
  exit 1
fi

mkdir -p "$BUILD_DIR/Payload"
cp -R "$APP_PATH" "$BUILD_DIR/Payload/NFCove.app"

(
  cd "$BUILD_DIR"
  /usr/bin/zip -qry "NFCove-unsigned.ipa" Payload
)

rm -rf "$BUILD_DIR/Payload"
echo "Created $IPA_PATH"
