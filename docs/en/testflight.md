# NFCove 0.4.0 TestFlight preflight

NFCove requires a physical NFC-capable iPhone and an Apple Developer provisioning profile that carries the **Near Field Communication Tag Reading** entitlement.

## Before Archive

1. Run `scripts/preflight-testflight.sh` on the Mac.
2. In Certificates, Identifiers & Profiles, enable **Near Field Communication Tag Reading** for `com.tiburonns.NFCove`.
3. Create/download an App Store distribution profile for that App ID.
4. Confirm the profile contains `com.apple.developer.nfc.readersession.formats = TAG`.
5. Use an Apple Distribution certificate.
6. Test read, save, reopen, original-NDEF details, write saved scan, normal write/read-back verification, unsupported/read-only tags, cancellation, and session timeout on a real iPhone.
7. Test English, Spanish, System language, large Dynamic Type, and VoiceOver.

`UIRequiredDeviceCapabilities = nfc` is intentional because NFCove's primary function requires NFC.

## Archive / TestFlight

1. Open `NFCove.xcodeproj` with Xcode 26 or later. CI uses the `macos-26` runner and rejects an older Xcode.
2. Select your paid Developer Team.
3. Confirm the NFC capability is present under Signing & Capabilities.
4. Product > Archive.
5. Organizer > Validate App.
6. Distribute App > App Store Connect > Upload.
7. Start with Internal Testing.

The release workflow defaults to `app-store-connect` export and `Apple Distribution` when signing secrets are configured. Its signing script rejects a profile whose application identifier does not match the app or whose NFC formats do not include `TAG`.

If installation reports that the device lacks NFC capability on an NFC-capable iPhone, inspect the embedded provisioning profile first; an App ID/profile without the NFC entitlement is not equivalent to the committed entitlement file.
