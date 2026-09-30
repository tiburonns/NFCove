# NFCove — App Store release checklist

This checklist is for the first public NFCove release. The App Store build should expose only functionality that is implemented and physically validated.

## Proposed listing

- **Name:** NFCove
- **Subtitle:** Read, save & write NFC
- **Primary category:** Utilities
- **Bundle ID:** `com.tiburonns.NFCove`
- **Supported device family:** iPhone
- **Minimum OS:** iOS 18
- **Languages:** English and Spanish

### Description

NFCove is a native NFC utility for iPhone. Read compatible NDEF tags, inspect their records, save scans for later, create common NFC records, write them to compatible tags, and verify the result after writing.

Saved scans keep their original NDEF fields when available, including TNF, type, identifier, payload, and record order. NFCove stores its library locally on the device and does not require an NFCove account.

### Keywords

`NFC,NDEF,tag,reader,writer,scan,utility,automation,contactless`

## Review notes

NFCove requires a physical NFC-capable iPhone. Core NFC does not function in the iOS Simulator.

Suggested App Review note:

> NFCove reads and writes user-presented NDEF tags using Core NFC. To test, open Scan, tap Start Scan, and present a compatible NDEF tag near the top of the iPhone. Create can write Text, URL, Email, Phone, SMS, and Location records to a writable tag and immediately verifies the data by reading it back. No account or login is required.

Do not claim arbitrary NFC-card emulation, UID cloning, payment-card cloning, or access-credential cloning.

## App privacy

The current release has no analytics SDK, advertising SDK, account system, or NFCove backend. NFC data and the library are processed and stored locally. App Store Connect privacy answers must remain consistent with the shipped build and `PrivacyInfo.xcprivacy`.

A public privacy-policy URL is still required in App Store Connect. The ready-to-host policy text is in [privacy-policy.md](privacy-policy.md).

## Screenshots

Prepare English and Spanish screenshots from the final signed build:

1. Home
2. Scan ready
3. Successful scan with records and tag information
4. Saved scanned tag detail
5. Create & Write
6. Library with scanned tags and created cards

Use real UI from the release build. Do not show unfinished or future functionality.

## Final external release gate

Before submission:

- Add the final App Icon / asset catalog.
- Publish the privacy policy at a public HTTPS URL.
- Provide a public Support URL.
- Complete App Store Connect age-rating questions.
- Upload localized screenshots and metadata.
- Validate the archive with Xcode 26 or newer.
- Run the full physical acceptance plan on the exact submitted commit.
- Upload to TestFlight Internal Testing first.
- Confirm the App Store distribution profile includes the NFC `TAG` entitlement.
