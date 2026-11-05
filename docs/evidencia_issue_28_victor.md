# Evidencia preliminar de pruebas — Issue #28 (catálogo estudiantil)

## 2026-11-05 — Aceptación de Roberth sobre la integración publicada

Responsable de esta revisión: roberdeleon, grupo #1. Base remota comprobada: `codex/28-integracion-almacenamiento`, `c491e29a7ed8a54a86f83f17d5b120d024945d40`. Se creó `test/28-aceptacion-roberth` en una copia nueva; las ramas/copias locales anteriores, incluidas modificaciones de la copia revision-33, se conservaron.

Se verificaron `SharedCatalogReader`, la composición productiva de EasyHomeApp y sus providers: lector, controlador de búsqueda y callbacks de borrar/restaurar usan la misma instancia del repositorio compartido. El snapshot se transporta sin reconstrucción, incluidos token/sequence. El controller se dispone mediante ref.onDispose y no depende del filtro; CatalogUndoHost envuelve el Scaffold por fuera de los estados del listado. No se recreó la conexión ni se editó código de producción.

La corrección de Roberth `9ae84a5` ya está incorporada como `fca1a38`: el patch-id del controller coincide (`d33ed0553e334acffbe2b8e3bd7c720c230ffa9f`). No se incorporó otra vez. El commit de Víctor `cfc830490daa0ee4b78909e0b220f42c716ab4b2` NO era ancestro de la base y su archivo de siete pruebas no existía allí. Se incorporó mediante cherry-pick como `091970c`, conservando autor y fecha. Solo hubo conflicto de bitácora, resuelto conservando íntegramente las dos historias. No se añadió una entrada nueva de Roberth a la bitácora; su texto se entrega a Kenneth para consolidación.

### Niveles de evidencia

| Suite | Fuente y alcance real |
|---|---|
| catalog_acceptance_victor_test.dart, QA01–QA07 | Las siete pruebas originales de Víctor, con repositorio y snapshot falsos, sin persistencia. Se conservan sin reescribirlas como supuestas pruebas persistentes. |
| catalog_shared_storage_integration_test.dart | Cuatro pruebas de Kenneth: composición real y repositorio productivo con backend de preferencias controlado en memoria. Sus 83 pruebas reportadas son reproducibles: al añadir las siete de Víctor la base pasa con 90. |
| catalog_persistent_acceptance_test.dart, REAL01–REAL07 | Siete widget tests nuevos sobre EasyHomeApp/ResultsPage y los providers/reader/controller de producción. El repositorio real serializa JSON, genera tokens/secuencias y publica revisiones confirmadas. El backend de preferencias es controlado en memoria; la subclase observadora cuenta consultas y llamadas, y permite inyectar carga/error de consulta. No sustituye la lógica de escritura/restauración. |
| catalog_persistent_acceptance_test.dart, REAL08 | Cadena controller → repositorio real → backend de preferencias en archivo temporal → nueva instancia → lector real. Conserva datos canónicos/orden, una baja y la restauración previa, sin resembrar. No es un widget test ni el backend nativo del navegador. |
| Navegador local | Arranque debug y release, login, catálogo, detalle y recarga. No se repite como propia la prueba de cierre/reapertura del navegador que Kenneth documentó en c491e29. |

REAL01 comprueba tipo + departamento + universidad, exclusión de no disponibles y ausencia de consultas extra al repetir filtro, reconstruir o cambiar de pestaña. REAL02 comprueba detalle con los campos canónicos y la misma posición de scroll. REAL03 borra dos registros filtrados por ID y restaura snapshots exactos, datos completos (description, isOwned y listas incluidos) y orden global. REAL04 retrasa la escritura real del backend y repite el gesto en la misma posición; solo se solicita un borrado, se mantiene el estado confirmado y un filtro durante la escritura conserva host/controller. REAL05 provoca fallos de escritura de baja/restauración y Reintentar conserva el mismo snapshot, sin éxito falso ni duplicados. REAL06 verifica la identidad del host a través de carga, error de consulta, recuperación, vacío y datos; Deshacer no fuerza visibilidad fuera del filtro. REAL07 cubre expiración y desmontaje con una escritura pendiente, y un controller nuevo al volver a montar.

### Resultados reales de esta rama

| Comando | Resultado |
|---|---|
| flutter pub get | Correcto; sin cambio de dependencias/lockfile. Se retiró la exclusión automática de analysis_options.yaml generada por Flutter. |
| dart format --output=none --set-exit-if-changed lib test | 68 archivos, 0 cambios, código 0. |
| flutter analyze --no-pub | No issues found, código 0. |
| flutter test --no-pub --reporter expanded | 98 pruebas aprobadas: 83 de la base + 7 de Víctor + 8 nuevas. |
| flutter build web --no-pub | Built build/web, código 0. Aviso preexistente de fuente CupertinoIcons no incluida; no impide compilar. |

El primer harness nuevo creaba la cola del repositorio fuera de la zona de testWidgets; se corrigió su creación y desmontaje antes del cierre de streams. Para la E/S real se utiliza una prueba asíncrona normal independiente del reloj falso. Se ajustó el viewport de aceptación a 1200×1000 para que los botones no queden cubiertos por el SnackBar. No se silencian avisos de hit-test ni se retiran aserciones para obtener resultados positivos.

### Investigación de la pantalla blanca — resultado: no reproducida de forma persistente

- Entorno: Windows; Flutter 3.47.7, Dart 3.13.5. Navegador integrado de ChatGPT/Codex, sesión `01a1a9a5-5cb1-76d2-9a2b-172dbe67355e`. Perfil administrado de esta sesión, no el perfil de Víctor. User-Agent recibido por el servidor: `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36`. No se conoce ni se accedió a la ruta interna del perfil.
- Debug: `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8097 --no-pub`, URL `http://127.0.0.1:8097/`. Salida: `Launching lib\\main.dart on Web Server in debug mode`, `Waiting for connection ... 20,6s`, `lib\\main.dart is being served at http://127.0.0.1:8097`. El servidor indica que depurar con web-server requiere la extensión Dart Debug; la ejecución de la app cargó sin ella.
- Consola debug (13:53:41–13:53:48 UTC / 07:53:41–07:53:48 Guatemala): carga DDC de 719 scripts y `Starting application from main method ... web_entrypoint.dart`. Cero errores/advertencias capturados; login y ResultsPage mostraron las dos tarjetas iniciales.
- Sondeo HTTP debug desde terminal: `/`, `/flutter_bootstrap.js`, `/main.dart.js` y `/dart_sdk.js` respondieron 200. Esto es un sondeo adicional, no una captura HAR del navegador.
- Release: `flutter build web --no-pub`, seguido de `node ../serve_acceptance.cjs build/web`, servido en `http://127.0.0.1:8098/`. El script temporal de diagnóstico registra método, ruta, status y User-Agent; no cambia archivos de la app y se incluye con los registros de la entrega. Solicitudes observadas de `/`, bootstrap, main.dart.js, favicon, FontManifest.json y MaterialIcons: todas 200. No hay 4xx/5xx en ese registro. La captura es de recursos del mismo origen; no es una auditoría completa de tráfico CDN ni un HAR.
- Consola release: cero errores/advertencias capturados. Se abrió el catálogo y detalle. Un gesto confirmó la baja de una tarjeta de siembra del origen de prueba; el aviso expiró antes de poder accionar Deshacer desde la herramienta. No se presenta ese intento como Deshacer manual aprobado; la restauración se verifica con las suites automatizadas.
- Al recargar release se observó un fotograma blanco durante el arranque, seguido de login normal en la siguiente observación, sin errores de consola. No equivale a la pantalla blanca persistente reportada. Capturas locales: aceptacion-debug-catalogo.jpg, aceptacion-release-catalogo.jpg y aceptacion-release-recarga.jpg; registros de servidor/consola guardados con la evidencia de la entrega.

**Conclusión limitada:** esta reproducción con comandos y perfil identificados no permite atribuir el reporte al almacenamiento, al CDN ni a otra causa. Para reproducir exactamente lo observado por Víctor faltan su comando completo, URL/origen, navegador/versión, perfil, duración del blanco y primera excepción de consola/red. No se borraron sus datos ni se modificó configuración de seguridad. Tampoco se afirma una nueva prueba de cierre/reapertura completo del navegador.

Pendientes: revisión humana, reproducción en el entorno original de Víctor, cierre/reapertura con el mismo perfil por el equipo y consolidación de la bitácora por Kenneth. Mis alojamientos/proveedores/adaptador, almacenamiento y dependencias permanecen fuera del cambio. No se cierra #28 ni se hace merge a main.

**Responsable de pruebas:** Víctor Horacio de León Fuentes  
**Issue:** #28 — S15 Grupo 1: filtro por tipo y borrar con Deshacer  
**Base:** `main` después de integrar PR #30 (`58166bf`).  
**Alcance:** pruebas y documentación; sin cambios en navegación ni almacenamiento compartido.

## Resultados reales antes de agregar las pruebas nuevas

| Comando | Resultado observado |
|---|---|
| `git pull --ff-only origin main` | Fast-forward `08f775c..58166bf` correcto. |
| `flutter pub get` | `Got dependencies!`; aviso de siete paquetes con versiones más recientes fuera de restricciones. |
| `flutter test` | `00:17 +17: All tests passed!` (17 pruebas previas; no valida por sí solo el issue #28). |
| `flutter build web` | `Built build\\web`; compilación web correcta. Aviso no bloqueante sobre CupertinoIcons/MaterialIcons. |
| `dart format --output=none --set-exit-if-changed lib test` | **Pendiente de ejecución**. |
| `flutter analyze` | **Pendiente de ejecución**. |
| Nuevas pruebas `issue_28_preparacion_test.dart` | **Pendiente de ejecución en equipo local**. |
| CI de PR #28 | **Pendiente**. |

## Matriz de pruebas del issue #28

| Caso | Resultado/evidencia al corte |
|---|---|
| Todos, Apartamento, Pensionado actualizan tarjetas | **Preparado para ejecución** en nuevo widget test. El código previo filtra localmente. |
| Tipo sin coincidencias muestra estado vacío | **Preparado para ejecución** en nuevo widget test. |
| Error presenta Reintentar y recupera la lista | **Parcial**: preparada una prueba de recuperación en controlador, pero la vista actual no presenta botón `Reintentar`. |
| Dismissible borra alojamiento por ID | **Bloqueado**: aún no se implementa `Dismissible` en la vista de `main`. |
| Deshacer restaura ID y todos sus campos | **Bloqueado**: repositorio actual solo expone `getAccommodations`. |
| Borrado fallido mantiene registro visible | **Bloqueado**: pendiente implementación del borrado. |
| Restauración fallida informa el error sin duplicar | **Bloqueado**: pendiente implementación de restauración. |
| Reconstrucción o mismo filtro no repite consultas | **Preparado para ejecución** en la arquitectura anterior. Debe ajustarse para verificar `ref.watch` tras integración. |
| Borrado/restauración permanecen tras reiniciar app | **Bloqueado**: no hay persistencia de borrado/restauración en repositorio actual. |
| Publicaciones de propietarios siguen visibles | **Pendiente de verificación**, requiere comprobar integración sin afectar datos compartidos. |

## Problemas identificados

1. En `main`, `ResultsPage` usa `ChangeNotifierProvider` y filtrado del controlador; no usa aún el Notifier inmutable ni `ref.watch` requeridos por #28.
2. No se encontró `Dismissible`, `SnackBar` con `Deshacer` o interfaz de repositorio para borrar/restaurar alojamientos en el listado estudiantil.
3. El controlador contiene `errorMessage` y permite recargar mediante `loadData`, pero `ResultsPage` no presenta `Reintentar`.
4. El almacenamiento en memoria disponible no ofrece persistencia del borrado/restauración al cerrar la app.

## Evidencias adicionales necesarias al terminar implementación

- Capturas/video: filtro Todos, Apartamento, Pensionado; lista vacía; error/Reintentar; gesto Dismissible; Deshacer.
- Prueba de fallos simulados de borrado y restauración.
- Captura o log que compare el ID y **todos** los campos antes/después de Deshacer.
- Cerrar completamente y abrir aplicación, confirmar el mismo estado persistente.
- Registro de comandos, resultados, `git diff --check` y enlace al CI del PR.
- Actualizar las pruebas conforme a la API definitiva de la implementación del equipo.

## Pregunta obligatoria del PR

La key de `Dismissible` debe usar el **ID estable** del alojamiento, no su índice en la lista. Si se borra la fila 2 de 5, las filas 3, 4 y 5 se desplazan y cambian de índice; una key basada en índice puede asociar animaciones o estado a otra tarjeta. El ID pertenece al alojamiento y se mantiene igual al filtrar, borrar y restaurar.

> Estado de entrega: **preparación y línea base**, no certificación de aceptación del issue #28. Solo marcar los criterios como aprobados una vez ejecutados con resultados reales.

### Resultados de validacion - Victor - Issue #28

- Formato: 37 archivos revisados, 0 cambios.
- flutter analyze: No issues found.
- flutter test: 21 pruebas aprobadas.
- flutter build web: compilacion exitosa.
- git diff --check: sin errores.
- Pendiente: validar borrado, Deshacer, errores y persistencia sobre la implementacion definitiva del issue #28.


## QA de aceptacion - Victor - 04/11/2026

Rama: test/28-aceptacion-victor
Issue: #28

Resultados:
- 7 pruebas nuevas de aceptacion aprobadas.
- flutter test: 49 pruebas aprobadas.
- flutter analyze: sin problemas.
- flutter build web: compilacion exitosa.
- git diff --check: sin errores.

Alcance:
- Pruebas con fuente controlada.
- Componentes temporales del PR #32.
- Sin modificar ResultsPage ni almacenamiento.

Pendiente:
- Validar la integracion definitiva.
- Verificar sincronizacion y persistencia real.
- Comprobar funcionamiento al reiniciar la aplicacion.


## 2026-11-05 - Entrega final de catalogo, PR #33

Base de preparacion: 8c88063 mas historial de Roberth d82a432, sin rama #35 ni pantalla de propietario. Esta entrega por separado pasa 100 pruebas, formato de 70 archivos sin cambios, analisis sin problemas y compilacion web sin CDN aprobada. No confundir con las 116 pruebas de la preparacion conjunta.

El almacenamiento #34 debe integrarse primero a main. Luego este PR del grupo #1 requiere CI y revision humana del grupo #2. La entrega del propietario tendra un PR final separado. La validacion manual de borrado/restauracion tras cerrar el navegador se documentara sobre la preparacion conjunta y no se sustituye por REAL08.
