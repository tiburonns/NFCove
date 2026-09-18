# Arquitectura de NFCove

## Principios

NFCove se organiza por funcionalidades con una pequeña capa Core alrededor de los frameworks de Apple. La interfaz no debe comunicarse directamente con Core NFC; las operaciones NFC pasan por `NFCSessionManager` y la creación NDEF por `NDEFBuilder`.

## Capas

- **App**: entrada de la aplicación, navegación por tabs, preferencias de idioma y stores compartidos.
- **Core/NFC**: sesiones Core NFC, codificación, decodificación y comprobación de capacidades.
- **Models**: tipos de valor compartidos por funcionalidades y servicios.
- **Features**: pantallas SwiftUI independientes.
- **Resources**: localizaciones, entitlements y configuración.

## Roadmap

1. Base: lectura/escritura NDEF, parser, biblioteca local y localización.
2. Constructor de records: mensajes con múltiples records reordenables y más tipos.
3. Inteligencia de tags: capacidad, lectura/escritura, compatibilidad y verificación.
4. Plantillas e historial: configuraciones reutilizables, búsqueda, carpetas y favoritos.
5. Herramientas avanzadas: `NFCTagReaderSession`, ISO 7816, ISO 15693, FeliCa y MIFARE cuando iOS y el tag lo permitan.
6. Automatización: App Intents / Atajos y flujos NFC reutilizables.
7. Sincronización: iCloud privado para metadatos de biblioteca y plantillas.

## Regla de seguridad

Las operaciones irreversibles (por ejemplo, bloquear permanentemente un tag NDEF escribible) deben pedir confirmación explícita y nunca presentarse como reversibles.
