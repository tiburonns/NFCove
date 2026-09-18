# NFCove

**Lee. Crea. Automatiza.**

NFCove es una herramienta NFC moderna y nativa para iPhone. El proyecto comienza con lo esencial —leer y escribir registros NDEF— y está diseñado para crecer hasta convertirse en una biblioteca visual NFC, constructor de automatizaciones, inspector de etiquetas, escritor por lotes, verificador y toolkit avanzado para desarrolladores.

> Documentación: [English](README.md) · **Español**

## Base actual

- Interfaz nativa en SwiftUI
- Lector NDEF con Core NFC
- Escritura NDEF para Texto, URL, Email y Teléfono
- Parser de payloads legible para humanos
- Biblioteca local para elementos NFC guardados
- Modos Inglés, Español e Idioma del sistema
- Arquitectura preparada para plantillas, historial, verificación, escritura por lotes, App Intents, sincronización con iCloud y protocolos avanzados
- Sin dependencias externas en tiempo de ejecución

## Requisitos

- Xcode 16 o posterior
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

Consulta [docs/es/architecture.md](docs/es/architecture.md) para ver la arquitectura y el roadmap, y [docs/es/ipa.md](docs/es/ipa.md) para compilar y firmar el IPA.

## Dirección del producto

NFCove no busca ser una copia visual de otras utilidades NFC. La meta es hacer que los flujos NFC se sientan como una experiencia de primera clase del ecosistema Apple: records visuales, plantillas reutilizables, compatibilidad clara, verificación segura después de escribir, biblioteca organizada e integración profunda con Atajos.

## Privacidad

Las lecturas y escrituras NFC se realizan localmente mediante Core NFC de Apple. La base actual no requiere una cuenta y no envía el contenido NFC a ningún servidor.

## Estado

Base inicial / desarrollo activo.
