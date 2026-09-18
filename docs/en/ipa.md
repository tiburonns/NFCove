# Building NFCove as an IPA

NFCove supports two IPA paths:

## Unsigned IPA

The repository includes `scripts/build-unsigned-ipa.sh`. It builds the Release app for a generic iOS device and packages it as:

`build/NFCove-unsigned.ipa`

This artifact is **not directly installable on a stock iPhone** until it is signed. It is useful for signing/sideloading tools that apply a valid Apple signature during installation.

## Signed IPA

Use `scripts/build-signed-ipa.sh` with an Apple signing certificate and a provisioning profile that includes the NFC capability.

Required environment variables:

- `P12_PATH`
- `P12_PASSWORD`
- `PROVISIONING_PROFILE_PATH`
- `KEYCHAIN_PASSWORD`

Optional:

- `BUNDLE_ID` (default: `com.tiburonns.NFCove`)
- `EXPORT_METHOD` (default: `development`)
- `SIGNING_IDENTITY` (default: `Apple Development`)

A successful signed export is copied to:

`build/NFCove.ipa`

For development or Ad Hoc distribution, the destination iPhone must be included in the provisioning profile. Apple documents that exported IPA files for registered devices are installable on devices covered by that profile.

## GitHub Actions

The `iOS Build and IPA` workflow runs on pushes and pull requests. Every successful run publishes `NFCove-unsigned.ipa` as an artifact.

To also produce `NFCove.ipa`, configure these repository secrets:

- `IOS_P12_BASE64`
- `IOS_P12_PASSWORD`
- `IOS_PROFILE_BASE64`
- `IOS_KEYCHAIN_PASSWORD`
- `IOS_BUNDLE_ID` (optional)
- `IOS_EXPORT_METHOD` (optional; `development`, `ad-hoc`, or another valid Xcode export method)
- `IOS_SIGNING_IDENTITY` (optional)

The provisioning profile must match the bundle identifier and include Near Field Communication Tag Reading.

## Local Xcode export

You can also archive from Xcode and export for a registered device. Xcode generates an `.ipa` when exporting an iOS archive for device distribution.
