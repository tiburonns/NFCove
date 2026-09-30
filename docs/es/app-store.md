# NFCove — Checklist de release para App Store

Este checklist corresponde a la primera versión pública de NFCove. La build enviada debe mostrar únicamente funciones implementadas y validadas físicamente.

## Ficha propuesta

- **Nombre:** NFCove
- **Subtítulo:** Lee, guarda y escribe NFC
- **Categoría principal:** Utilidades
- **Bundle ID:** `com.tiburonns.NFCove`
- **Dispositivos:** iPhone
- **Sistema mínimo:** iOS 18
- **Idiomas:** Español e inglés

### Descripción

NFCove es una utilidad NFC nativa para iPhone. Lee tags NDEF compatibles, inspecciona sus records, guarda escaneos para consultarlos después, crea records NFC comunes, escríbelos en tags compatibles y verifica el resultado inmediatamente después de escribir.

Los escaneos guardados conservan los campos NDEF originales cuando están disponibles, incluyendo TNF, tipo, identificador, payload y orden de records. NFCove guarda su biblioteca localmente y no requiere una cuenta de NFCove.

### Keywords

`NFC,NDEF,tag,lector,escritor,escaneo,utilidad,automatización,contactless`

## Notas para App Review

NFCove requiere un iPhone físico compatible con NFC. Core NFC no funciona en el simulador de iOS.

Nota sugerida:

> NFCove lee y escribe tags NDEF presentados por el usuario mediante Core NFC. Para probarla, abre Escanear, pulsa Iniciar escaneo y acerca un tag NDEF compatible a la parte superior del iPhone. Crear permite escribir Texto, URL, Email, Teléfono, SMS y Ubicación en un tag escribible y verifica el resultado mediante una relectura inmediata. No requiere cuenta ni inicio de sesión.

No anunciar emulación NFC arbitraria, clonación de UID, clonación de tarjetas bancarias ni clonación de credenciales de acceso.

## Privacidad de App Store

La versión actual no contiene SDK de analítica, publicidad, sistema de cuentas ni backend de NFCove. Los datos NFC y la biblioteca se procesan y almacenan localmente. Las respuestas de privacidad en App Store Connect deben coincidir con la build y con `PrivacyInfo.xcprivacy`.

App Store Connect todavía requiere una URL pública para la política de privacidad. El texto listo para publicar está en [privacy-policy.md](privacy-policy.md).

Después de publicar las páginas de privacidad y soporte, asigna en el target los build settings `NFCOVE_PRIVACY_POLICY_URL` y `NFCOVE_SUPPORT_URL` con las mismas URLs HTTPS públicas utilizadas en App Store Connect. NFCove sólo muestra estos enlaces en Ajustes cuando contienen URLs HTTPS válidas; los valores vacíos se ocultan intencionalmente.

## Capturas

Prepara capturas en español e inglés usando la build firmada final:

1. Inicio
2. Escanear listo
3. Escaneo correcto con records e información del tag
4. Detalle de tag escaneado guardado
5. Crear y escribir
6. Biblioteca con tags escaneados y tarjetas creadas

Usa UI real de la build de release. No muestres funciones futuras o incompletas.

## Gate externo final

Antes del envío:

- Agregar App Icon / asset catalog definitivo.
- Publicar la política de privacidad en una URL HTTPS pública.
- Proporcionar una Support URL pública.
- Completar el cuestionario de clasificación por edades.
- Subir metadata y capturas localizadas.
- Validar el archive con Xcode 26 o posterior.
- Ejecutar el plan de aceptación físico sobre el commit exacto enviado.
- Subir primero a TestFlight Internal Testing.
- Confirmar que el perfil de distribución App Store incluya el entitlement NFC `TAG`.
