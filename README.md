# NFCove

**Read. Build. Automate.**

NFCove is a modern, native NFC toolkit for iPhone. The project starts with the essentials—reading and writing NDEF records—and is designed to grow into a visual NFC library, automation builder, tag inspector, batch writer, verifier, and advanced developer toolkit.

> Documentation: **English** · [Español](README.es.md)

> **Current development version:** 0.3.0 (build 6). Tagged releases are produced from the same tested IPA pipeline used by CI.

## Current foundation

- Native SwiftUI interface
- Core NFC NDEF reader using the current `TAG` NFC entitlement
- NDEF writer for Text, URL, Email, Phone, SMS, and Location records
- Human-readable payload parser
- Local library stored atomically in Application Support, with migration from the earlier preferences-backed format
- Saved library items can be opened in a dedicated Use Card view, launched with their matching iPhone action, or written directly back to a compatible tag
- URL, email, phone, SMS, and location content is normalized and validated before an NDEF message is created
- Post-write read-back verification for compatible NDEF tags
- Portable core tests run in CI for normalization, persistence, migration, and corrupt-store preservation
- English, Spanish, and System Language modes
- Architecture prepared for templates, history, verification, batch writing, App Intents, iCloud sync, and expert tag protocols
- No third-party runtime dependencies

## Requirements

- Xcode 16 or newer
- iOS 18 or newer
- A physical NFC-capable iPhone for NFC operations
- An Apple Developer signing setup with the **Near Field Communication Tag Reading** capability enabled

Core NFC sessions do not run in the iOS Simulator.

## Run

1. Clone the repository.
2. Open `NFCove.xcodeproj` in Xcode.
3. Select the `NFCove` target.
4. Choose your development team under **Signing & Capabilities**.
5. Ensure the NFC capability is available for the selected App ID.
6. Build and run on a physical iPhone.

## Project structure

```text
NFCove/
├── App/            App entry point, navigation, language and shared stores
├── Core/NFC/       Core NFC session and NDEF encoding logic
├── Features/       Home, Scan, Create, Library and Settings
├── Models/         Shared app and NFC models
└── Resources/      Info.plist, entitlements and localization
```

See [docs/en/architecture.md](docs/en/architecture.md) for the architecture and roadmap, [docs/en/ipa.md](docs/en/ipa.md) for IPA builds and signing, [docs/en/testing.md](docs/en/testing.md) for the physical-device release gate, and [docs/en/testflight.md](docs/en/testflight.md) for the TestFlight preflight.

## Product direction

NFCove is intentionally not a visual clone of existing NFC utilities. The goal is to make NFC workflows feel like a first-class Apple platform experience: visual records, reusable templates, clear compatibility feedback, safe write verification, organized tag libraries, and deep Shortcuts integration.

## Privacy

NFC reads and writes happen locally through Apple's Core NFC framework. The current foundation does not require an account and does not send NFC contents to a server.

## Status

Active development. The current foundation is buildable/tested in CI, while NFC read/write behavior still requires a physical NFC-capable iPhone for final hardware validation.
