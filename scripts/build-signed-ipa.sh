#!/bin/bash
set -euo pipefail

: "${P12_PATH:?Set P12_PATH to an Apple signing certificate (.p12)}"
: "${PROVISIONING_PROFILE_PATH:?Set PROVISIONING_PROFILE_PATH to a .mobileprovision file}"
: "${P12_PASSWORD:?Set P12_PASSWORD}"
: "${KEYCHAIN_PASSWORD:?Set KEYCHAIN_PASSWORD}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/NFCove-signed.xcarchive"
EXPORT_DIR="$BUILD_DIR/SignedExport"
PROFILE_PLIST="$BUILD_DIR/profile.plist"
EXPORT_PLIST="$BUILD_DIR/ExportOptions.generated.plist"
KEYCHAIN_PATH="$BUILD_DIR/nfcove-build.keychain-db"

BUNDLE_ID="${BUNDLE_ID:-com.tiburonns.NFCove}"
EXPORT_METHOD="${EXPORT_METHOD:-development}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Apple Development}"

mkdir -p "$BUILD_DIR"
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR" "$KEYCHAIN_PATH" "$PROFILE_PLIST" "$EXPORT_PLIST"

security cms -D -i "$PROVISIONING_PROFILE_PATH" > "$PROFILE_PLIST"
PROFILE_NAME=$(/usr/libexec/PlistBuddy -c "Print :Name" "$PROFILE_PLIST")
PROFILE_UUID=$(/usr/libexec/PlistBuddy -c "Print :UUID" "$PROFILE_PLIST")
TEAM_ID=$(/usr/libexec/PlistBuddy -c "Print :TeamIdentifier:0" "$PROFILE_PLIST")

mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
cp "$PROVISIONING_PROFILE_PATH" "$HOME/Library/MobileDevice/Provisioning Profiles/$PROFILE_UUID.mobileprovision"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import "$P12_PATH" -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security list-keychains -d user -s "$KEYCHAIN_PATH" login.keychain-db

xcodebuild   -project "$ROOT_DIR/NFCove.xcodeproj"   -scheme NFCove   -configuration Release   -destination "generic/platform=iOS"   -archivePath "$ARCHIVE_PATH"   PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID"   DEVELOPMENT_TEAM="$TEAM_ID"   CODE_SIGN_STYLE=Manual   CODE_SIGN_IDENTITY="$SIGNING_IDENTITY"   PROVISIONING_PROFILE_SPECIFIER="$PROFILE_NAME"   archive

cat > "$EXPORT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$EXPORT_METHOD</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key>
        <string>$PROFILE_NAME</string>
    </dict>
</dict>
</plist>
PLIST

xcodebuild   -exportArchive   -archivePath "$ARCHIVE_PATH"   -exportOptionsPlist "$EXPORT_PLIST"   -exportPath "$EXPORT_DIR"

IPA=$(find "$EXPORT_DIR" -maxdepth 1 -name "*.ipa" -print -quit)
if [[ -z "$IPA" ]]; then
  echo "Signed IPA was not produced." >&2
  exit 1
fi

cp "$IPA" "$BUILD_DIR/NFCove.ipa"
echo "Created $BUILD_DIR/NFCove.ipa"
