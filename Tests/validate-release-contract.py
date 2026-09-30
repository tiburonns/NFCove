#!/usr/bin/env python3
import plistlib
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

project = (ROOT / "NFCove.xcodeproj/project.pbxproj").read_text(
    encoding="utf-8"
)
readme_en = (ROOT / "README.md").read_text(encoding="utf-8")
readme_es = (ROOT / "README.es.md").read_text(encoding="utf-8")
strings_en = (
    ROOT / "NFCove/Resources/en.lproj/Localizable.strings"
).read_text(encoding="utf-8")
strings_es = (
    ROOT / "NFCove/Resources/es.lproj/Localizable.strings"
).read_text(encoding="utf-8")
testing_en = (ROOT / "docs/en/testing.md").read_text(encoding="utf-8")
testing_es = (ROOT / "docs/es/testing.md").read_text(encoding="utf-8")
testflight_en = (ROOT / "docs/en/testflight.md").read_text(encoding="utf-8")
testflight_es = (ROOT / "docs/es/testflight.md").read_text(encoding="utf-8")

versions = set(
    re.findall(r"MARKETING_VERSION = ([0-9.]+);", project)
)
builds = set(
    re.findall(r"CURRENT_PROJECT_VERSION = ([0-9]+);", project)
)
if len(versions) != 1 or len(builds) != 1:
    raise SystemExit(
        f"version contract failed: versions={sorted(versions)} "
        f"builds={sorted(builds)}"
    )

version = next(iter(versions))
build = next(iter(builds))

if f"**Current development version:** {version} (build {build})." not in readme_en:
    raise SystemExit(
        "version contract failed: English README is stale"
    )
if f"**Versión actual de desarrollo:** {version} (build {build})." not in readme_es:
    raise SystemExit(
        "version contract failed: Spanish README is stale"
    )

for label, text in [
    ("English physical test plan", testing_en),
    ("Spanish physical test plan", testing_es),
]:
    if not text.startswith(f"# NFCove {version} "):
        raise SystemExit(
            f"version contract failed: {label} is stale"
        )

if not testflight_en.startswith(
    f"# NFCove {version} TestFlight preflight"
):
    raise SystemExit(
        "version contract failed: English TestFlight guide is stale"
    )
if not testflight_es.startswith(
    f"# NFCove {version} — Preflight de TestFlight"
):
    raise SystemExit(
        "version contract failed: Spanish TestFlight guide is stale"
    )

if f"This describes NFCove {version}." not in strings_en:
    raise SystemExit(
        "version contract failed: English privacy copy is stale"
    )
if f"Esto describe NFCove {version}." not in strings_es:
    raise SystemExit(
        "version contract failed: Spanish privacy copy is stale"
    )

key_pattern = re.compile(r'^\s*"([^"]+)"\s*=', re.MULTILINE)
keys_en_list = key_pattern.findall(strings_en)
keys_es_list = key_pattern.findall(strings_es)
keys_en = set(keys_en_list)
keys_es = set(keys_es_list)

duplicates_en = sorted(
    key for key, count in Counter(keys_en_list).items() if count > 1
)
duplicates_es = sorted(
    key for key, count in Counter(keys_es_list).items() if count > 1
)
if duplicates_en or duplicates_es:
    raise SystemExit(
        "localization contract failed: duplicate keys "
        f"en={duplicates_en} es={duplicates_es}"
    )

if keys_en != keys_es:
    raise SystemExit(
        "localization contract failed: languages differ "
        f"missing_es={sorted(keys_en - keys_es)} "
        f"missing_en={sorted(keys_es - keys_en)}"
    )

ui_sources = "\n".join(
    (
        ROOT / path
    ).read_text(encoding="utf-8")
    for path in [
        "NFCove/Features/Home/HomeView.swift",
        "NFCove/Features/Settings/SettingsView.swift",
        "NFCove/Features/Library/SavedCardUseView.swift",
    ]
)
for forbidden in [
    "home.roadmap",
    "settings.expert",
    "comingSoon",
    "library.use.nfc.generic",
    "library.use.nfc.secure",
]:
    if forbidden in ui_sources:
        raise SystemExit(
            f"release UI contract failed: unfinished UI token {forbidden}"
        )

with (ROOT / "NFCove/Resources/NFCove.entitlements").open("rb") as handle:
    entitlements = plistlib.load(handle)

info_path = ROOT / "NFCove/Resources/Info.plist"
info_text = info_path.read_text(encoding="utf-8")
if info_text.count(
    "<key>ITSAppUsesNonExemptEncryption</key>"
) != 1:
    raise SystemExit(
        "release contract failed: ITSAppUsesNonExemptEncryption "
        "must appear exactly once"
    )

with info_path.open("rb") as handle:
    info = plistlib.load(handle)

if info.get("UIRequiredDeviceCapabilities") != ["nfc"]:
    raise SystemExit(
        "capability contract failed: UIRequiredDeviceCapabilities "
        "must require nfc"
    )
if not info.get("NFCReaderUsageDescription"):
    raise SystemExit(
        "capability contract failed: NFCReaderUsageDescription is missing"
    )
if info.get("ITSAppUsesNonExemptEncryption") is not False:
    raise SystemExit(
        "release contract failed: NFCove should declare "
        "no non-exempt encryption"
    )

formats = entitlements.get(
    "com.apple.developer.nfc.readersession.formats",
    []
)
if "TAG" not in formats:
    raise SystemExit(
        "capability contract failed: current TAG reader entitlement is missing"
    )
if "NDEF" in formats:
    raise SystemExit(
        "capability contract failed: deprecated NDEF entitlement "
        "must not be shipped"
    )

with (ROOT / "NFCove/Resources/PrivacyInfo.xcprivacy").open(
    "rb"
) as handle:
    privacy = plistlib.load(handle)

if privacy.get("NSPrivacyTracking") is not False:
    raise SystemExit(
        "privacy contract failed: NFCove must declare tracking=false"
    )

reasons = {}
for item in privacy.get("NSPrivacyAccessedAPITypes", []):
    reasons[item.get("NSPrivacyAccessedAPIType")] = set(
        item.get("NSPrivacyAccessedAPITypeReasons", [])
    )

if "CA92.1" not in reasons.get(
    "NSPrivacyAccessedAPICategoryUserDefaults",
    set(),
):
    raise SystemExit(
        "privacy contract failed: UserDefaults reason CA92.1 is missing"
    )

for path in [
    "docs/en/testflight.md",
    "docs/es/testflight.md",
    "docs/en/app-store.md",
    "docs/es/app-store.md",
    "docs/en/privacy-policy.md",
    "docs/es/privacy-policy.md",
]:
    if not (ROOT / path).exists():
        raise SystemExit(
            f"release documentation contract failed: missing {path}"
        )

model_source = (
    ROOT / "NFCove/Models/NFCRecordModels.swift"
).read_text(encoding="utf-8")
session_source = (
    ROOT / "NFCove/Core/NFC/NFCSessionManager.swift"
).read_text(encoding="utf-8")
builder_source = (
    ROOT / "NFCove/Core/NFC/NDEFBuilder.swift"
).read_text(encoding="utf-8")

for token in [
    "typeNameFormatRaw",
    "identifier: Data?",
    "payload: Data?",
    "var hasOriginalNDEF",
]:
    if token not in model_source:
        raise SystemExit(
            f"NDEF archive contract failed: missing {token}"
        )

for token in [
    "payload.typeNameFormat.rawValue",
    "type: payload.type",
    "identifier: payload.identifier",
    "payload: payload.payload",
]:
    if token not in session_source:
        raise SystemExit(
            f"NDEF scan contract failed: missing {token}"
        )

for token in [
    "static func message(from card: SavedScanCard)",
    "NFCTypeNameFormat(rawValue:",
    "NFCNDEFPayload(",
]:
    if token not in builder_source:
        raise SystemExit(
            f"NDEF rebuild contract failed: missing {token}"
        )

if "DEVELOPMENT_TEAM =" in project:
    raise SystemExit(
        "build contract failed: project must not hardcode an Apple team"
    )

workflow = (
    ROOT / ".github/workflows/ios-build.yml"
).read_text(encoding="utf-8")
for token in [
    "runs-on: macos-26",
    "Build Release for iOS Simulator",
    "SWIFT_TREAT_WARNINGS_AS_ERRORS=YES",
    "NFCove App Store candidates require Xcode 26 or newer.",
    "app-store-connect",
    "Apple Distribution",
]:
    if token not in workflow:
        raise SystemExit(
            f"release CI contract failed: missing {token}"
        )

signed_script = (
    ROOT / "scripts/build-signed-ipa.sh"
).read_text(encoding="utf-8")
for token in [
    'EXPORT_METHOD="${EXPORT_METHOD:-app-store-connect}"',
    'SIGNING_IDENTITY="${SIGNING_IDENTITY:-Apple Distribution}"',
    "SWIFT_TREAT_WARNINGS_AS_ERRORS=YES",
]:
    if token not in signed_script:
        raise SystemExit(
            f"signed archive contract failed: missing {token}"
        )

asset_catalog = ROOT / "NFCove/Resources/Assets.xcassets"
if not asset_catalog.exists():
    print(
        "WARN: final App Icon / Assets.xcassets is still external "
        "to this hardening pass."
    )

print(
    f"PASS: NFCove {version} (build {build}) release contract, "
    "NFC entitlement, privacy, localization parity, original NDEF "
    "archive, App Store docs, and Xcode 26 CI"
)
