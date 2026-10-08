<p align="center">
  <img src="Design/AppIcon-Source.png" width="180" alt="Icono de la app NFCove">
</p>

# NFCove

**Lee. Crea. Automatiza.**

NFCove es una utilidad NFC nativa para iPhone enfocada en un flujo NDEF confiable: leer, inspeccionar, guardar, crear, escribir y verificar tags NFC compatibles.

> Documentación: [English](README.md) · **Español**

> **Versión actual de desarrollo:** 0.4.0 (build 8). Las releases por tag se generan con la misma ruta de IPA probada por CI.

## Base actual

- Interfaz nativa en SwiftUI
- Lector NDEF con Core NFC usando el entitlement NFC actual `TAG`
- Escritura NDEF para Texto, URL, Email, Teléfono, SMS y Ubicación
- Parser de payloads legible para humanos
- Los escaneos pueden guardarse en Biblioteca conservando TNF, tipo, identificador, payload y orden original de records NDEF cuando están disponibles
- Biblioteca local guardada de forma atómica en Application Support, con migración desde el formato anterior basado en preferencias
- Los escaneos y tarjetas creadas pueden volver a abrirse y escribirse en un tag compatible con verificación por relectura
- URL, email, teléfono, SMS y ubicación se normalizan y validan antes de crear el mensaje NDEF
- Verificación mediante relectura después de escribir en tags NDEF compatibles
- Pruebas portables de lógica en CI para normalización, persistencia, migración y preservación de archivos corruptos
- Modos Inglés, Español e Idioma del sistema
- Sin dependencias externas en tiempo de ejecución

## Requisitos

- Xcode 26 o posterior para builds de App Store/TestFlight
- iOS 18 o posterior
- Un iPhone físico compatible con NFC para las operaciones NFC
- Firma de Apple Developer con la capacidad **Near Field Communication Tag Reading** habilitada

Las sesiones de Core NFC no funcionan en el simulador de iOS.

## Ejecutar

1. Clona el repositorio.
2. Abre `NFCove.xcodeproj` en Xcode.
3. Selecciona el target `NFCove`.
4. Selecciona tu equipo de desarrollo en **Signing & Capabilities**.
5. Verifica que la capacidad NFC esté disponible para el App ID seleccionado.
6. Compila y ejecuta en un iPhone físico.

## Estructura

```text
NFCove/
├── App/            Entrada de la app, navegación, idioma y stores compartidos
├── Core/NFC/       Sesiones Core NFC y codificación NDEF
├── Features/       Inicio, Escanear, Crear, Biblioteca y Ajustes
├── Models/         Modelos compartidos de la app y NFC
└── Resources/      Info.plist, entitlements y localización
```

Consulta [docs/es/architecture.md](docs/es/architecture.md) para la arquitectura, [docs/es/ipa.md](docs/es/ipa.md) para compilar y firmar el IPA, [docs/es/testing.md](docs/es/testing.md) para la aceptación física, [docs/es/testflight.md](docs/es/testflight.md) para TestFlight y [docs/es/app-store.md](docs/es/app-store.md) para el envío a App Store.

## Dirección del producto

NFCove no busca ser una copia visual de otras utilidades NFC. La meta es hacer que los flujos NFC comunes se sientan como una experiencia de primera clase del ecosistema Apple: resultados claros, almacenamiento local confiable, compatibilidad transparente y escritura verificada.

## Privacidad

Las lecturas y escrituras NFC se realizan localmente mediante Core NFC de Apple. La base actual no requiere una cuenta y no envía el contenido NFC a ningún servidor.

## Estado

Hardening de release para 0.4.0. CI usa macOS 26 / Xcode 26+, mientras que la aceptación NFC final todavía requiere un iPhone físico compatible. Las URLs públicas de privacidad/soporte, capturas y metadata de App Store Connect son elementos externos del gate final.

## Contacto, soporte y feedback

¿Tienes una **duda**, **sugerencia**, encontraste un **error** o quieres compartir **feedback** sobre NFCove? Usa el formulario de GitHub Issues del proyecto:

**[Abrir formulario de contacto y feedback](https://github.com/tiburonns/NFCove/issues/new?template=feedback.yml)**

**[❤️ Apoyar el desarrollo en Patreon](https://www.patreon.com/tiburonns)**

Selecciona la categoría que mejor corresponda: **Duda, Sugerencia, Error, Feedback, Compatibilidad u Otro**. Incluye la versión de la app, dispositivo/sistema y pasos para reproducir el problema cuando aplique.

No publiques contraseñas, tokens, claves, direcciones privadas ni otra información personal sensible. Para vulnerabilidades de seguridad, utiliza el proceso indicado en `SECURITY.md` cuando esté disponible.

