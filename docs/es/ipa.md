# Compilar NFCove como IPA

NFCove admite dos rutas para generar un IPA:

## IPA sin firma

El repositorio incluye `scripts/build-unsigned-ipa.sh`. Compila la versión Release para un dispositivo iOS genérico y empaqueta:

`build/NFCove-unsigned.ipa`

Este archivo **no se puede instalar directamente en un iPhone normal** hasta que tenga una firma válida. Sirve para herramientas de firma/sideload que aplican la firma de Apple durante la instalación.

## IPA firmado

Usa `scripts/build-signed-ipa.sh` con un certificado de firma de Apple y un provisioning profile que incluya la capacidad NFC.

Variables obligatorias:

- `P12_PATH`
- `P12_PASSWORD`
- `PROVISIONING_PROFILE_PATH`
- `KEYCHAIN_PASSWORD`

Opcionales:

- `BUNDLE_ID` (por defecto: `com.tiburonns.NFCove`)
- `EXPORT_METHOD` (por defecto: `development`)
- `SIGNING_IDENTITY` (por defecto: `Apple Development`)

Si la exportación termina correctamente se crea:

`build/NFCove.ipa`

Para distribución Development o Ad Hoc, el iPhone de destino debe estar incluido en el provisioning profile.

## GitHub Actions

El workflow `iOS Build and IPA` se ejecuta en pushes y pull requests. Cada ejecución exitosa publica `NFCove-unsigned.ipa` como artefacto.

Para generar también `NFCove.ipa`, configura estos secrets del repositorio:

- `IOS_P12_BASE64`
- `IOS_P12_PASSWORD`
- `IOS_PROFILE_BASE64`
- `IOS_KEYCHAIN_PASSWORD`
- `IOS_BUNDLE_ID` (opcional)
- `IOS_EXPORT_METHOD` (opcional)
- `IOS_SIGNING_IDENTITY` (opcional)

El provisioning profile debe coincidir con el bundle identifier e incluir Near Field Communication Tag Reading.

## Exportación local desde Xcode

También puedes crear un Archive en Xcode y exportarlo para un dispositivo registrado. Xcode genera un archivo `.ipa` al exportar un archive de iOS para distribución en dispositivos.
