# NFCove 0.4.0 — Physical Device Acceptance Plan

[Español](../es/testing.md) · **English**

NFC behavior must be accepted on a physical NFC-capable iPhone. Simulator builds and portable core tests cannot prove antenna/session behavior, tag compatibility, signing capabilities, or real read-after-write verification.

## Release gate

Do not publish a release tag until every applicable test below passes on the exact commit being tagged. Record device model, iOS, Xcode, commit SHA, tag model/capacity, and installation path.

## Build and launch

1. Clone `main` and open `NFCove.xcodeproj`.
2. Select a valid Apple Development team and a physical NFC-capable iPhone.
3. Confirm **Near Field Communication Tag Reading** is enabled for the App ID and the built app entitlement contains `TAG` (not deprecated `NDEF`).
4. Build and launch.
5. Confirm Home, Scan, Create, Library, and Settings fill the available screen in portrait and landscape.
6. Test **System Language**, **English**, and **Español**, relaunching after each selection.

Expected: no launch crash, no square/constrained root UI, no localization keys exposed, and language selection persists.

## Read matrix

Use known-good NDEF tags containing Text, HTTPS URL, `mailto:` email, `tel:` phone, `sms:` message, `geo:` location, multiple NDEF records, an empty NDEF message, and an unclassified NDEF payload.

For every tag: start a scan, present one tag, confirm the native NFC sheet appears, confirm capacity/access when Core NFC exposes it, and verify recognized content is human-readable. Unknown NDEF content must remain inspectable instead of crashing.

After every successful scan, tap **Save scan**, give it a name, open **Library → Scanned tags**, reopen it, and verify that record count, values, byte sizes, capacity, access state, and scan date remain available after force-quitting and relaunching NFCove.

For a newly saved scan, expand **Technical details** and verify TNF, Type, Identifier, and Payload are present for each NDEF record. For a multi-record tag, confirm record order is unchanged. Then choose **Write saved scan to NFC tag**, write to a second compatible tag, and scan it back. The saved scan should report **Original** rather than **Reconstructed**.

## Write and read-back verification

For Text, URL, Email, Phone, SMS, and Location: enter a valid value, confirm non-zero estimated size, write to a writable tag with enough capacity, keep the tag in range through verification, confirm **written and verified**, then scan it again and compare the visible value.

Also verify that `example.com` becomes `https://example.com`, formatted phone numbers normalize correctly, email becomes `mailto:`, malformed input cannot be written, oversized messages are rejected, read-only tags are rejected, and removing the tag before verification never produces verified success.

## Multiple-tag handling

Present two tags simultaneously during read and write. NFCove must request a single tag and resume polling without crashing or silently choosing one.

## Library lifecycle

1. Save one item of every supported kind, leaving the optional name blank on at least one.
2. Force-quit and reopen NFCove; all items must remain.
3. Tap every saved item and open **Use saved card**. Text must copy; URL, email, phone, SMS, and location must resolve to the matching iPhone action.
4. From the same screen choose **Write saved card to NFC tag**; the result must verify and scan back correctly.
5. Delete an item, relaunch, and confirm deletion persists.

## Legacy library migration

Upgrade over a build that stored `nfcove.library.items` in UserDefaults without deleting app data. Existing items must appear, survive another relaunch, and the legacy preference must only disappear after the new file was safely written.

## Accessibility and UI

Test the main flows with large Dynamic Type, VoiceOver, portrait, and landscape. Buttons must retain understandable labels and hints, content must remain reachable, and no screen may be constrained to a centered square.

## Failure paths

Test user cancellation, moving the phone away mid-session, read-only/unsupported tags, and rapid repeated button taps. NFCove must never report verified success after failure, must prevent overlapping sessions, and must allow a new session without restarting the app.

## IPA acceptance

For an unsigned IPA that is re-signed during sideloading, verify that the installed signature/App ID retains the NFC entitlement, then perform at least one real read and one verified write. For a signed IPA produced by `scripts/build-signed-ipa.sh`, verify the provisioning profile matches the bundle ID and includes NFC before repeating the same hardware test.

An IPA that installs but cannot open a Core NFC session does **not** pass release acceptance.

## Acceptance result

A candidate passes only when all six supported record kinds read/write/verify, newly scanned NDEF records preserve their original raw fields and can be written back, invalid/capacity/read-only/multiple-tag cases fail safely, library/migration preserve data, accessibility checks pass, all language modes behave correctly, and the intended IPA path retains NFC capability.