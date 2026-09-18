# NFCove Architecture

## Principles

NFCove is organized by feature with a small Core layer around Apple frameworks. UI code should not speak directly to Core NFC; NFC operations are routed through `NFCSessionManager` and NDEF creation through `NDEFBuilder`.

## Layers

- **App**: application entry point, tab navigation, language preferences, shared stores.
- **Core/NFC**: Core NFC sessions, encoding, decoding, capability checks.
- **Models**: value types shared by features and services.
- **Features**: independent SwiftUI screens.
- **Resources**: localizations, entitlements, configuration.

## Roadmap

1. Foundation: NDEF reading/writing, parser, local library, localization.
2. Record builder: reorderable multi-record messages and more record types.
3. Tag intelligence: capacity, writable/read-only state, compatibility and verification.
4. Templates and history: reusable configurations, search, folders and favorites.
5. Advanced tools: `NFCTagReaderSession`, ISO 7816, ISO 15693, FeliCa and MIFARE where supported by iOS and the tag.
6. Automation: App Intents / Shortcuts and reusable NFC workflows.
7. Sync: private iCloud synchronization for library metadata and templates.

## Safety rule

Operations that are irreversible (for example, locking a writable NDEF tag) must require an explicit confirmation and must never be presented as reversible.
