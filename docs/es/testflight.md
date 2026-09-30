# NFCove 0.4.0 — Preflight de TestFlight

NFCove requiere un iPhone físico compatible con NFC y un perfil de Apple Developer que incluya **Near Field Communication Tag Reading**.

## Antes del Archive

1. Ejecuta `scripts/preflight-testflight.sh` en la Mac.
2. En Certificates, Identifiers & Profiles activa **Near Field Communication Tag Reading** para `com.tiburonns.NFCove`.
3. Crea/descarga un perfil de distribución App Store para ese App ID.
4. Confirma que incluya `com.apple.developer.nfc.readersession.formats = TAG`.
5. Usa certificado Apple Distribution.
6. Prueba lectura, guardar/reabrir, detalles NDEF originales, escribir un escaneo guardado, escritura/verificación normal, tags no compatibles/read-only, cancelación y timeout en iPhone real.
7. Prueba Sistema, English, Español, Dynamic Type grande y VoiceOver.

`UIRequiredDeviceCapabilities = nfc` es intencional porque la función principal de NFCove requiere NFC.

## Archive / TestFlight

1. Abre `NFCove.xcodeproj` con Xcode 26 o posterior. CI usa el runner `macos-26` y rechaza versiones anteriores.
2. Selecciona tu Team de pago.
3. Confirma NFC en Signing & Capabilities.
4. Product > Archive.
5. Organizer > Validate App.
6. Distribute App > App Store Connect > Upload.
7. Empieza con Internal Testing.

El workflow de release usa por defecto `app-store-connect` y `Apple Distribution` cuando existen secrets de firma. El script rechaza perfiles que no correspondan al bundle ID o no contengan `TAG`.

Si un iPhone compatible muestra un error de “sin capacidad NFC”, revisa primero el provisioning profile embebido: el entitlement del repo no sustituye la capability habilitada en el App ID/perfil.
