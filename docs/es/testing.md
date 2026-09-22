# NFCove 0.2.3 — Plan de aceptación en dispositivo físico

**Español** · [English](../en/testing.md)

El comportamiento NFC debe aceptarse en un iPhone físico compatible. Las pruebas de simulador y lógica no pueden demostrar el comportamiento real de la antena/sesión, compatibilidad de tags, capacidades de firma ni la verificación por relectura.

## Puerta de release

No publiques un tag hasta que todas las pruebas aplicables pasen sobre el commit exacto. Registra modelo de iPhone, iOS, Xcode, SHA, modelo/capacidad del tag y método de instalación.

## Compilación e inicio

1. Clona `main` y abre `NFCove.xcodeproj`.
2. Selecciona un equipo Apple Development válido y un iPhone físico con NFC.
3. Confirma **Near Field Communication Tag Reading** en el App ID y que el entitlement compilado contenga `TAG` (no el valor deprecado `NDEF`).
4. Compila y abre la app.
5. Confirma que Inicio, Escanear, Crear, Biblioteca y Ajustes ocupen correctamente la pantalla en vertical y horizontal.
6. Prueba **Idioma del sistema**, **English** y **Español**, reabriendo la app después de cada selección.

Resultado esperado: sin crash, sin interfaz encerrada en un cuadro, sin claves de localización visibles y con persistencia del idioma.

## Matriz de lectura

Usa tags NDEF conocidos con Texto, URL HTTPS, email `mailto:`, teléfono `tel:`, mensaje `sms:`, ubicación `geo:`, varios records NDEF, mensaje NDEF vacío y un payload no clasificado.

En cada tag inicia el escaneo, presenta un solo tag, confirma la hoja nativa de NFC, revisa capacidad/acceso cuando Core NFC lo proporcione y verifica que el contenido reconocido sea legible. El contenido NDEF desconocido debe poder inspeccionarse sin cerrar la app.

## Escritura y verificación por relectura

Para Texto, URL, Email, Teléfono, SMS y Ubicación: introduce un valor válido, confirma tamaño mayor que cero, escribe en un tag con capacidad suficiente, mantenlo cerca durante la verificación, confirma **escrito y verificado** y vuelve a escanearlo.

Comprueba además que `example.com` se convierta en `https://example.com`, los teléfonos formateados se normalicen, el email se convierta en `mailto:`, las entradas inválidas no puedan escribirse, los mensajes demasiado grandes se rechacen, los tags de sólo lectura se rechacen y alejar el tag antes de verificar nunca produzca éxito verificado.

## Varios tags

Presenta dos tags simultáneamente durante lectura y escritura. NFCove debe pedir uno solo y reanudar el polling sin crash ni elegir silenciosamente uno.

## Ciclo de Biblioteca

1. Guarda un elemento de cada tipo y deja el nombre opcional vacío en al menos uno.
2. Cierra a la fuerza y abre NFCove; todos deben permanecer.
3. Desliza un elemento y usa **Escribir en tag**; debe verificarse y escanearse correctamente.
4. Elimina un elemento, reabre y confirma que la eliminación persista.

## Migración de biblioteca anterior

Actualiza encima de una compilación que guardaba `nfcove.library.items` en UserDefaults sin borrar los datos. Los elementos deben aparecer, sobrevivir otro relanzamiento y la preferencia anterior sólo debe eliminarse después de escribir correctamente el nuevo archivo.

## Casos de fallo

Prueba cancelación, alejar el teléfono a mitad de sesión, tags de sólo lectura/no compatibles y pulsaciones rápidas repetidas. NFCove nunca debe anunciar éxito verificado tras un fallo, debe impedir sesiones superpuestas y permitir iniciar otra sesión sin reiniciar.

## Aceptación de IPA

En una IPA sin firma vuelta a firmar por sideload, confirma que la firma/App ID instalada conserve el entitlement NFC y realiza una lectura real y una escritura verificada. En una IPA firmada por `scripts/build-signed-ipa.sh`, confirma que el provisioning profile coincida con el bundle ID e incluya NFC antes de repetir la prueba.

Una IPA que se instala pero no puede abrir una sesión Core NFC **no** pasa aceptación.

## Resultado

El candidato pasa únicamente cuando los seis tipos soportados leen/escriben/verifican, los casos inválidos/capacidad/sólo lectura/varios tags fallan de forma segura, Biblioteca y migración conservan datos, los tres modos de idioma funcionan y la ruta de IPA conserva la capacidad NFC.