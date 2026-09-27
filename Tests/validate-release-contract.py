#!/usr/bin/env python3
import plistlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / "NFCove.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
readme_en = (ROOT / "README.md").read_text(encoding="utf-8")
readme_es = (ROOT / "README.es.md").read_text(encoding="utf-8")
strings_en = (ROOT / "NFCove/Resources/en.lproj/Localizable.strings").read_text(encoding="utf-8")
strings_es = (ROOT / "NFCove/Resources/es.lproj/Localizable.strings").read_text(encoding="utf-8")
testing_en = (ROOT / "docs/en/testing.md").read_text(encoding="utf-8")
testing_es = (ROOT / "docs/es/testing.md").read_text(encoding="utf-8")

versions = set(re.findall(r"MARKETING_VERSION = ([0-9.]+);", project))
builds = set(re.findall(r"CURRENT_PROJECT_VERSION = ([0-9]+);", project))
if len(versions) != 1 or len(builds) != 1:
    raise SystemExit(f"version contract failed: versions={sorted(versions)} builds={sorted(builds)}")

version = next(iter(versions))
build = next(iter(builds))

if f"**Current development version:** {version} (build {build})." not in readme_en:
    raise SystemExit("version contract failed: English README is stale")
if f"**Versión actual de desarrollo:** {version} (build {build})." not in readme_es:
    raise SystemExit("version contract failed: Spanish README is stale")

if not testing_en.startswith(f"# NFCove {version} "):
    raise SystemExit("version contract failed: English physical test plan is stale")
if not testing_es.startswith(f"# NFCove {version} "):
    raise SystemExit("version contract failed: Spanish physical test plan is stale")

if f"This describes NFCove {version}." not in strings_en:
    raise SystemExit("version contract failed: English privacy copy is stale")
if f"Esto describe NFCove {version}." not in strings_es:
    raise SystemExit("version contract failed: Spanish privacy copy is stale")

with (ROOT / "NFCove/Resources/NFCove.entitlements").open("rb") as handle:
    entitlements = plistlib.load(handle)
info_path = ROOT / "NFCove/Resources/Info.plist"
info_text = info_path.read_text(encoding="utf-8")
if info_text.count("<key>ITSAppUsesNonExemptEncryption</key>") != 1:
    raise SystemExit(
        "release contract failed: ITSAppUsesNonExemptEncryption must appear exactly once"
    )
with info_path.open("rb") as handle:
    info = plistlib.load(handle)

if info.get("UIRequiredDeviceCapabilities") != ["nfc"]:
    raise SystemExit("capability contract failed: UIRequiredDeviceCapabilities must require nfc")
if not info.get("NFCReaderUsageDescription"):
    raise SystemExit("capability contract failed: NFCReaderUsageDescription is missing")
if info.get("ITSAppUsesNonExemptEncryption") is not False:
    raise SystemExit("release contract failed: NFCove should declare no non-exempt encryption")
if not (ROOT / "docs/en/testflight.md").exists() or not (ROOT / "docs/es/testflight.md").exists():
    raise SystemExit("release contract failed: bilingual TestFlight guides are missing")

formats = entitlements.get("com.apple.developer.nfc.readersession.formats", [])
if "TAG" not in formats:
    raise SystemExit("capability contract failed: current TAG reader entitlement is missing")
if "NDEF" in formats:
    raise SystemExit("capability contract failed: deprecated NDEF entitlement must not be shipped")

with (ROOT / "NFCove/Resources/PrivacyInfo.xcprivacy").open("rb") as handle:
    privacy = plistlib.load(handle)

if privacy.get("NSPrivacyTracking") is not False:
    raise SystemExit("privacy contract failed: NFCove must declare tracking=false")

reasons = {}
for item in privacy.get("NSPrivacyAccessedAPITypes", []):
    reasons[item.get("NSPrivacyAccessedAPIType")] = set(
        item.get("NSPrivacyAccessedAPITypeReasons", [])
    )

if "CA92.1" not in reasons.get("NSPrivacyAccessedAPICategoryUserDefaults", set()):
    raise SystemExit("privacy contract failed: UserDefaults reason CA92.1 is missing")

if "DEVELOPMENT_TEAM =" in project:
    raise SystemExit("build contract failed: project must not hardcode an Apple team")

workflow = (ROOT / ".github/workflows/ios-build.yml").read_text(encoding="utf-8")
for token in [
    "Build Release for iOS Simulator",
    "SWIFT_TREAT_WARNINGS_AS_ERRORS=YES",
    "app-store-connect",
    "Apple Distribution",
]:
    if token not in workflow:
        raise SystemExit(f"release CI contract failed: missing {token}")

signed_script = (ROOT / "scripts/build-signed-ipa.sh").read_text(encoding="utf-8")
for token in [
    'EXPORT_METHOD="${EXPORT_METHOD:-app-store-connect}"',
    'SIGNING_IDENTITY="${SIGNING_IDENTITY:-Apple Distribution}"',
    "SWIFT_TREAT_WARNINGS_AS_ERRORS=YES",
]:
    if token not in signed_script:
        raise SystemExit(f"signed archive contract failed: missing {token}")

print(f"PASS: NFCove {version} (build {build}) version, NFC entitlement, privacy, bilingual docs, and TestFlight signing defaults")
