# Bitácora de uso de IA

## 2026-11-04 — Roberth: revisión de conexión #33 y desmontaje

- Herramienta: Codex. Se revisaron #32, #33 (`343446f`), #34 (`09381fa`), su retroalimentación publicada, archivos de conexión, contrato y providers del repositorio real. El PDF S15/retroalimentación externa siguen ausentes; no se afirma haberlos leído.
- Autoría/alcance: los commits originales de Roberth ya son ancestros de #33. No se repitieron ni se incorporó código de Kenneth a la rama de #32. Coordinación de archivos publicada antes de editar en #33, comentario 6650302698. Solo se modifica el controller propio, su test, bitácora y evidencia existentes; sin ResultsPage, almacenamiento, dependencias ni Mis alojamientos.
- Hallazgo de integración: Kenneth mantiene el host fuera del Scaffold y estados de consulta, con controller independiente del filtro. La capacidad productiva sigue null hasta integrar #34. Las ocho pruebas originales de conexión pasan.
- Reproducción: tres aserciones fallaron al comprobar IDs bloqueados tras desmontar durante borrado, fallo de restauración o cancelación antes de entregar el evento. La prueba anterior de desmontaje solo comprobaba ausencia de excepciones; se amplió para verificar también bloqueo y número de operaciones.
- Corrección generada/revisada: liberar tickets cuando desaparece el último consumidor o termina una operación sin consumidor; conservar bloqueo durante la escritura/restauración pendiente. No se emiten éxitos ficticios ni se repiten escrituras. Nueva prueba de remontaje verifica Reintentar con el mismo snapshot; se descartó modificar el host o la pantalla para compensar el estado perdido del controller.
- Validación: 36 pruebas en rama propia; 65 pruebas en copia aislada de #33 con únicamente controller/tests corregidos; formato 41 y 56 archivos, respectivamente, sin cambios; análisis sin problemas en ambas copias. No se publica esa copia ni se añade #34 a ninguna rama. El resultado de CI y commit incremental se comunican en #32/#33 al concluir.
- Conexión futura: se documenta el tipo DeletedAccommodation con token/sequence y la necesidad de compartir instancia de repositorio entre lectura/callbacks. #34 sigue sin integrar; la conexión real y la validación persistente quedan pendientes de Kenneth/Víctor tras esa dependencia. No hay merge ni cierres automáticos.

## 2026-11-04 - Inicio S15 y base compartida

- Herramienta: Codex.
- Solicitud: comprobar si S15 existía; preparar instrucciones por grupo e iniciar el laboratorio respetando la rúbrica.
- Inspección: PDF local, código e historial de Easy Home, ramas y PR remotos; CI y plantilla del repositorio roberdeleon/pdm-s14-ci-estados.
- Resultado de la auditoría: navegación inicial y filtros del MVP existentes, pero S15 incompleto. No se encontró Dismissible/Deshacer ni CI en Easy Home.
- Propuesta corregida: repartir solo navegación/CI a un grupo y solo filtros al otro no dejaría un PR de filtro y Deshacer por grupo. Se decidió un listado por grupo y navegación compartida.
- Propuesta rechazada: asumir que ChangeNotifier y filtrado local existentes cumplen literalmente Notifier/ref.watch. Se incorpora Riverpod para navegación; los filtros S15 quedan para los PR de cada grupo.
- Adaptación: incorporar el CI de S14 con Flutter local 3.44.8 y compilación web, porque Easy Home no incluye proyecto Android. No se copió la aplicación de muestra S14.
- Código generado con asistencia: AppNavigation, AppShell, conexión con login/Inicio/Buscar, pruebas de navegación, workflow, plantilla y documentos de coordinación.
- Corrección de compatibilidad: reemplazar value obsoleto de DropdownButtonFormField por initialValue para evitar avisos del analizador.
- Limitación detectada: memoria permitida en página 1 frente a validación de reinicio de página 2. Se exige documentar y verificar persistencia real antes de marcar cumplimiento total.
- Git: rama local feat/navegacion creada. La creación de issue por conector falló con HTTP 403; el usuario creó posteriormente el issue #27 y el issue #28 en GitHub. No se publicó ni integró PR desde este trabajo.
- Validaciones: se registrarán abajo los resultados efectivos al finalizar las comprobaciones locales. CI remoto, revisión humana, filtros S15 y borrar/Deshacer todavía pendientes.

### Comprobaciones locales

- Primera ejecución: las tres pruebas nuevas de navegación pasaron; el recorrido MVP falló al tocar una tarjeta fuera de la zona visible por la nueva barra inferior. Se corrigió usando desplazamiento hasta la tarjeta antes del tap; no se silenció el aviso ni se eliminó la aserción del detalle.
- `dart format lib test`: normalizó también formato preexistente para que el check de S14 pueda aplicarse a todo lib/test. No se cambió la lógica de esos archivos adicionales.
- `dart format --output=none --set-exit-if-changed lib test`: 36 archivos, 0 cambios, código de salida 0.
- `flutter analyze`: No issues found, código de salida 0.
- `flutter test --reporter expanded`: 17 pruebas aprobadas, código de salida 0; incluye destinos, Ver todos, scroll conservado y recorrido MVP adaptado a AppShell.
- `flutter build web`: compilación finalizada, salida build/web, código de salida 0. El compilador también informa una referencia a fuente CupertinoIcons no incluida; la app usa MaterialIcons. No se agregó una dependencia de iconos para silenciar el aviso.
- `git diff --check`: sin errores de espacios. Los cambios siguen locales, sin commit, push, PR, revisión humana ni ejecución de Actions.

### Preferencia de entrega de instrucciones

- A petición del usuario se retiraron los dos archivos de prompts y el documento de coordinación generados localmente. Las instrucciones se entregan en el chat; la coordinación se centraliza en los issues de GitHub.
- Se conserva esta bitácora exigida por el laboratorio, sin copiar los prompts completos al repositorio.
## 2026-11-04 - Preparación de pruebas issue #28 (Víctor)

- **Herramienta:** ChatGPT (GPT-6), como apoyo en preparación de pruebas de Flutter.
- **Solicitud:** revisar issue #28 y preparar casos del filtro, estados vacío/error, borrado, Deshacer, fallos, consultas y persistencia.
- **Fuentes revisadas:** issue #28, estado de PR #30, `results_page.dart`, controlador, repositorio, datasource, pruebas existentes y bitácora.
- **Resultado:** se preparó el archivo de pruebas `issue_28_preparacion_test.dart` sin modificar navegación ni almacenamiento. Se identificaron funciones aún pendientes de implementación para no reportar falsos positivos.
- **Criterio humano:** mantener pruebas separadas del código productivo del equipo y no considerar aprobados los criterios de borrado, Deshacer o persistencia hasta ejecutarlos.
- **Resultados observados en PowerShell antes de incorporar las pruebas nuevas:** `flutter pub get` correcto; `flutter test` con 17 pruebas aprobadas; `flutter build web` correcto con avisos no bloqueantes.
- **Pendiente:** ejecutar formato, `flutter analyze`, nuevas pruebas y validar requisitos finales sobre `feat/28-filtro`, incluyendo CI y capturas.

## 2026-11-04 - Componentes aislados del catálogo, issue #28

- Herramienta: Codex. Solicitud: continuar el prompt del grupo #1 mientras se acuerda la fuente compartida con el grupo #2.
- Base: rama feat/28-filtro desde main con PR #31 integrado; se conservan las pruebas preliminares de Víctor.
- Implementado: CatalogFilter inmutable con igualdad por valor; Notifier; puerto de lectura CatalogReader; FutureProvider con ref.watch del filtro y revisión; componentes de filtro y estados con Reintentar y limpiar filtros.
- Corrección: los reintentos automáticos de Riverpod se deshabilitan solo para esta consulta, para que un error no genere consultas ocultas y la recuperación sea explícita con Reintentar.
- Coordinación recibida del grupo #2: implementarán entidades, repositorio, persistencia y Agregar alojamiento, proponiendo SharedPreferencesAsync con JSON versionado y operación add. Se adapta el puerto de lectura del catálogo a Stream<int> de revisiones, sin añadir ni modificar sus dependencias.
- Pruebas: filtro Todos/Apartamento/Pensionado, igualdad, conservación de ubicación, vacío y limpiar, carga, error/Reintentar, consultas repetidas, invalidación por revisión, lista no modificable y rechazo de respuesta obsoleta. Primera ejecución de los 13 casos iniciales aprobada; se añade prueba de revisión repetida tras adaptar Stream<int>.
- Límite deliberado: componentes todavía aislados de ResultsPage; el lector real se inyectará mediante adaptador cuando esté disponible el repositorio compartido. No se introduce otra persistencia, ni se modifica OwnerAccommodationStore, MyAccommodationsPage o Agregar alojamiento. Dismissible, Deshacer y reinicio siguen pendientes.
- No se publicaron comentarios ni solicitudes a compañeros; se entrega la confirmación propuesta en el chat para que el equipo la registre en #27.
- Validación final: `flutter test --reporter expanded`, 35 pruebas aprobadas (21 existentes y 14 nuevas); formato de 45 archivos sin cambios; `flutter analyze` sin problemas; `flutter build web` completado; `git diff --check` sin errores. Se corrigió un aviso del analizador por corchetes angulares en un comentario, sin cambios de lógica posteriores a las pruebas.

## 2026-11-04 - Integración de ResultsPage, Kenneth, issue #28

- Solicitud: ejecutar la integración del catálogo del grupo #1, conservando el trabajo existente y evitando cambios en el almacenamiento del grupo #2.
- Comprobación remota: no había PR o rama publicados del almacenamiento compartido ni del componente de Deshacer. No se inventaron sus clases ni se duplicó su implementación.
- Implementado: ResultsPage consume CatalogFilterBar y CatalogResultsSection, conserva sus tarjetas y detalle, ofrece filtro de universidad y mantiene departamento/universidad coherentes. Buscar entrega su ubicación al Notifier. Los cambios del Notifier actualizan el formulario legado sin provocar consultas adicionales.
- Adaptador provisional de lectura: CurrentCatalogReader consulta el mismo AccommodationRepository y OwnerAccommodationStore existentes; no almacena otra copia persistente ni incorpora shared_preferences. Las publicaciones notifican revisiones. CatalogScope conserva el lector entre rebuilds y centraliza su futuro reemplazo por la fuente compartida.
- Pruebas de Víctor y MVP adaptadas a la consulta asíncrona real: cambiar filtro sí consulta, repetirlo o reconstruir la pantalla no. No se eliminaron sus escenarios para aprobar.
- Se agregaron siete pruebas: estados y Reintentar en ResultsPage, coherencia de ubicación y limpiar, Buscar/pestañas sin recarga, composición real desde login, filtros del adaptador y notificación de publicaciones del propietario.
- Corrección durante pruebas: la pantalla de login tiene dos textos INICIAR SESIÓN; se seleccionó explícitamente el ElevatedButton para probar la entrada real.
- Validación: 42 pruebas aprobadas; flutter analyze sin problemas; formato de 50 archivos sin cambios; git diff --check sin errores; compilación web completada, con el aviso preexistente de fuente CupertinoIcons no incluida.
- Pendiente: revisar la API y el PR reales del grupo #2 y conectar su adaptador definitivo; integrar el componente de Roberth y validar Deshacer/errores/persistencia con Víctor. No cerrar #28 ni hacer merge automático. No se modificaron MyAccommodationsPage, OwnerAccommodationStore ni dependencias.

## 2026-11-04 - Revisión del PR #34 antes de integrar

- Se revisó el commit cd44f59 de feat/29-almacenamiento en una worktree temporal, sin cambiar la implementación del grupo #2 ni mezclarla aún en feat/28-filtro.
- Confirmaciones verificadas en #27: EmmanuelC-04 por grupo #2 y victordeleon172003 por grupo #1 aceptaron contrato y dependencia. CI remoto 41964533781 aprobado para cd44f59. El PR no tenía revisiones humanas registradas al consultar.
- Suite publicada reproducida localmente: 32 pruebas aprobadas. La resolución de dependencias en la copia temporal adapta el lockfile al SDK local; esos cambios no se trasladan a ninguna rama.
- Dos pruebas adicionales de revisión reproducen fallos de recuperación tras error inicial de lectura y de siembra. Ambas fallan: _ready se asigna una sola vez y conserva el Future fallido; query y escrituras vuelven a esperar el mismo error aunque el backend se recupere. Esto bloquea la recuperación mediante Reintentar si el fallo ocurre al inicializar.
- Las pruebas de reproducción permanecen en la copia temporal, fuera del repositorio de trabajo. Se entrega la observación al usuario para coordinar la corrección con Javier; no se publicó comentario o revisión en nombre de otra persona ni se hizo merge.
- Pendiente: corregir la inicialización recuperable en el PR #34 y ejecutar esas pruebas junto con las existentes antes de recomendar su integración; después conectar el adaptador definitivo y los componentes del PR #32 en #33.

## 2026-11-04 — Preparación de borrado y Deshacer (Roberth, #28)

- Herramienta: Codex; asistencia para inspección, diseño, implementación, pruebas y documentación. Las revisiones de IA no sustituyen la revisión humana del grupo #2.
- Fuentes: código e historial del repositorio autorizado, issues #27/#28 y comentarios de aceptación, PR #30/#31 y sus revisiones, evidencia de Víctor y rama feat/28-filtro. El usuario confirmó que el PDF y la retroalimentación externa no están en esta PC nueva; no se inventó su contenido.
- Cambios: controller genérico con callbacks del contrato acordado, wrapper Dismissible por ID, host de SnackBars, falso exclusivo de pruebas y evidencia. Sin editar ResultsPage, OwnerAccommodationStore ni persistencia; sin crear entidades definitivas de Javier. La integración requiere su API publicada y coordinación con Kenneth.
- Decisiones: conservar el snapshot por identidad; encolar avisos por operación; bloquear doble borrado/restauración; informar fallos y reintentar restauración; dejar que la consulta tras changes confirmado retire la fila, sin eliminación optimista ni onDismissed con escritura.
- Correcciones: la primera prueba detectó cierre incorrecto de SnackBars encolados al desmontar. Se sustituyó por un ScaffoldMessenger propio por pantalla. Se agregó expiración explícita del SnackBar con acción, se ajustó la espera de animación del gesto en la prueba y se excluyó el Dismissible interno del SnackBar del conteo de tarjetas. No se suprimieron excepciones de UI.
- Propuestas descartadas: duplicar persistencia, fabricar snapshots desde la tarjeta o su índice filtrado, sustituir el SnackBar anterior y modificar la pantalla de Kenneth antes de coordinar. Se descartaron cambios automáticos del SDK en configuración/dependencias.
- Coordinación: comentario publicado en #28 para Kenneth, Javier y Víctor; conector de escritura devolvió 403 y se usó GitHub CLI autenticado como roberdeleon.
- Validación local: Flutter 3.47.7 / Dart 3.13.5; formato 41 archivos sin cambios, análisis sin problemas, suite completa con 33 pruebas aprobadas (12 nuevas). El CI existente verifica Flutter 3.44.8. Evidencia y pendientes en docs/evidencia_issue_28_borrado.md.
- Pendiente de aceptación general: API real, integración de ResultsPage, sincronización con publicaciones de propietarios y verificación persistente tras cerrar/abrir. No se cierra #28 ni se hace merge automático.
- Entrega: PR #32 en borrador desde feat/28-borrado-deshacer. Compilación web local correcta, con aviso de fuente CupertinoIcons ya existente; git diff --check sin errores. Los checks y la descripción del PR registran el resultado de CI y la coordinación final. También se usó GitHub CLI para crear el PR tras 403 del conector.

## 2026-11-04 - Kenneth: conexión de componentes del PR #32 en ResultsPage

- Se incorporó la rama feat/28-borrado-deshacer en feat/28-filtro para conservar los commits de Roberth. No se integró ningún PR en main. El único conflicto fue la bitácora; se conservaron ambas historias, incluidas las observaciones del PR #34.
- ResultsPage envuelve las tarjetas con CatalogDismissible cuando recibe un CatalogDeletionController y mantiene CatalogUndoHost por encima de la consulta. La cola sobrevive a filtros, carga, errores y vacío. Las filas conservan keys por ID.
- La capacidad de escritura se inyecta mediante catalogDeletionControllerProvider. Por defecto es null porque el lector actual del MVP no escribe; no se fabricó otra persistencia ni se añadió un falso a producción. La conexión real a deleteById/restore del PR #34 sigue pendiente de su corrección y revisión.
- Se añadieron ocho pruebas de integración sobre ResultsPage, con fuente controlada exclusiva de test: identidad del snapshot/datos/orden, borrado fallido y repetición, restauración fallida con Reintentar, confirmación lenta y bloqueo de doble operación, filtro durante escritura, borrados consecutivos, host persistente ante error de consulta y fuente sin capacidad de escritura.
- Validación: ocho casos nuevos aprobados; suite completa con 62 pruebas aprobadas (42 previas, 12 de Roberth y 8 nuevas); flutter analyze sin problemas; formato de 56 archivos sin cambios; flutter build web correcto, con aviso preexistente de fuente CupertinoIcons. Se corrigieron llaves de una condición de test señaladas por el analizador, sin cambiar su comportamiento.
- Límite de aceptación: se verifica la integración de UI con callbacks y revisiones controladas, no borrado persistente real ni cierre/reapertura de la app. #28 permanece abierto; faltan el adaptador definitivo, validación de Víctor y revisión humana del grupo #2. No se publicaron mensajes a compañeros.

## 2026-11-04 - Issue #29: contrato de almacenamiento en worktree aislada

- Coordinación: se consultó #27 directamente y se cargaron todos sus comentarios; el issue permanece abierto y tiene 0 comentarios. La propuesta recibida en conversación no consta allí como confirmación de ambos grupos ni como aprobación de `shared_preferences`.
- Estado Git: `origin/main` se actualizó desde 58166bf a 2b1b8fa, merge del PR #31. Se creó `feat/29-almacenamiento` en una worktree temporal desde 2b1b8fa; `feat/29-filtro` y sus cambios sin commit permanecen en la worktree original.
- Contrato preparado en `domain/repositories/shared_accommodation_repository.dart`: consulta tipada; alta; borrado que devuelve snapshot; restauración por token; stream de eventos de cambios; orden estable; excepciones de duplicado y registro/token ausente. Eventos solo después de escritura durable en la implementación futura.
- Entidades nuevas: `AccommodationRecord` incluye id, nombre/título, tipo enum, ubicación, departamento, universidades, precio, descripción, disponibilidad, baños, tamaño, imágenes, contacto y correo; colecciones defensivas. `AccommodationQuery` filtra tipo, departamento, universidad y disponibilidad. `DeletedAccommodation` conserva objeto completo, token único y secuencia original para restaurar el orden al deshacer.
- Pruebas aisladas con fake en memoria (solo test): filtros combinados y orden; campos/colecciones; borrado/restauración completos; restauraciones consecutivas fuera de orden; operaciones repetidas/duplicados; errores de lectura/escritura y no modificación ante fallos; eventos de alta, baja y restauración.
- Persistencia propuesta (pendiente de aprobación, no implementada): `SharedPreferencesAsync` con una clave/versionado y un único JSON que incluya registros, siguiente secuencia y tombstones de borrado. Serializar escrituras para evitar actualizaciones perdidas; publicar eventos solo después de completar el `setString`; al iniciar, reconstruir registros y tombstones. Flutter documenta soporte web usando LocalStorage, pero advierte que el plugin es para preferencias sencillas y no garantiza escritura durable en disco; no tratarlo como BD crítica. Dependencia y lockfile sin cambios.
- Validación de este trabajo: prueba aislada Flutter de contrato, 7 aprobadas; `dart analyze` sobre los tipos/contrato/pruebas, sin problemas. No se ejecutó aún la suite completa ni build web de esta worktree.
- Pendiente: confirmar contrato y `shared_preferences` por los dos grupos en #27; después implementar persistencia real, prueba recreando el almacenamiento y conectar alta/listado en la integración autorizada. No se modificaron `ResultsPage`, navegación, CI, `pubspec.yaml` ni `pubspec.lock`.
- Validación ampliada de la worktree desde 2b1b8fa: suite completa `flutter test --no-pub`, 28 aprobadas (incluye evidencia del PR #31); formato global de 43 archivos, 0 cambios; análisis completo `dart analyze lib test`, sin problemas.
- Referencia para la propuesta de persistencia: documentación oficial del plugin [`shared_preferences`](https://pub.dev/packages/shared_preferences), que lista LocalStorage para web y advierte que sus escrituras no ofrecen garantía de persistencia durable tras retornar.

## 2026-11-04 - Implementación de almacenamiento compartido S15 (Javiersontay)

- Coordinación corregida respecto de la entrada de preparación: después de esa auditoría, EmmanuelC-04 confirmó la aceptación del grupo #2 y victordeleon172003 la del grupo #1, incluida la dependencia `shared_preferences`, en el issue #27. La autorización para implementar llegó después de ambas confirmaciones.
- Worktrees revisadas: `feat/29-filtro` sigue en `C:\Users\HP\pdm2026d-equipo-02-easyhome`; `feat/29-almacenamiento` se mantiene en `C:\Users\HP\pdm2026d-equipo-02-easyhome-almacenamiento`. Se conservaron íntegros los cambios sin commit de ambas ramas.
- Contrato final en `lib/features/accommodations/domain/repositories/shared_accommodation_repository.dart`: `query(AccommodationQuery)`, `add(AccommodationRecord)`, `deleteById(String)`, `restore(DeletedAccommodation)` y `Stream<int> get changes`.
- Persistencia implementada en `lib/features/accommodations/data/repositories/shared_accommodation_repository_impl.dart`: `SharedPreferencesAsync`, JSON con versión, una clave de estado para registros activos/tombstones/secuencias/revisión, siembra inicial una sola vez, escrituras serializadas y publicación de revisiones solamente después de escritura confirmada. Errores de escritura no cambian el estado en memoria ni notifican. Restauración conserva identidad, campos y orden original, y el mismo token es idempotente.
- `AccommodationQuery` tipado filtra tipo, departamento, universidad y `onlyOwned`. Se añadieron providers Riverpod para instancia única, revisión y consultas que vuelven a ejecutarse después de revisiones persistidas.
- `AddAccommodationPage` ahora agrega al repositorio compartido; el controlador de catálogo lee desde esa misma fuente y observa revisiones. No se modificaron `ResultsPage` ni `MyAccommodationsPage`; tampoco navegación ni CI.
- Pruebas: contrato con filtro/campos/orden/duplicados/errores/serialización/notificaciones; recreación del repositorio entre operaciones; prueba adicional con preferencias respaldadas por archivo temporal, confirmando alta, baja, restauración, ausencia de re-siembra y persistencia tras crear otra instancia. La prueba de providers ordena el cierre del contenedor antes del repositorio para cancelar listeners y evitar bloquear el cierre del stream.
- Dependencias: `shared_preferences: ^2.5.6` en producción y `shared_preferences_platform_interface: ^2.4.2` en desarrollo para probar el adaptador; `flutter pub get --offline` terminó con `Got dependencies!` y lockfile regenerado. Flutter también añadió exclusiones locales a `analysis_options.yaml`; se retiraron porque no pertenecían al cambio.
- Validación final: `dart format lib test` informó 46 archivos, 0 cambios; `flutter analyze --no-pub` informó `No issues found!`; `flutter test --no-pub` terminó con `All tests passed!` (31 pruebas antes de agregar la prueba respaldada por archivo); el contrato aislado tras agregarla terminó con 10 pruebas aprobadas; `flutter build web --no-pub` finalizó con `Built build/web` y código de salida 0. Build mostró avisos de fuente Cupertino no incluida y optimización MaterialIcons; la app compila correctamente.
- Límite de persistencia: el test de archivo verifica recreación durable del repositorio real detrás de la API SharedPreferencesAsync. La compilación web confirma compatibilidad de plataforma, pero no es una prueba e2e del navegador. El backend web de `shared_preferences` usa LocalStorage y su documentación aclara que la escritura no garantiza permanencia en disco tras retornar; no se presenta como una base de datos transaccional.
- No se hizo commit, push, PR, merge, cierre de issue ni comentario/revisión de compañeros. Pendiente: revisión humana del grupo #1 y decisión del usuario antes de cualquier publicación GitHub.

## 2026-11-04 - Revisión del commit b07401c para PR de almacenamiento (EmmanuelC-04)

- Herramienta: Codex. Se continuó desde `feat/29-almacenamiento` publicada por Javier; no se recreó el repositorio ni se modificaron `ResultsPage` o `MyAccommodationsPage`.
- Se comprobó en #27 la aceptación expresa de ambos grupos para el contrato y `shared_preferences`. Se revisaron entidades, serialización JSON versionada, siembra, orden de borrado/restauración, escrituras confirmadas, providers y pruebas de recreación del repositorio.
- Validación local del commit publicado: `dart format --output=none --set-exit-if-changed lib test` revisó 45 archivos, 0 cambios; `flutter analyze --no-pub` terminó sin problemas; `flutter test --no-pub --reporter expanded` aprobó 32 pruebas; `flutter build web --no-pub` produjo `build/web` con código 0. El aviso de fuente Cupertino no impidió la compilación.
- Corrección de alcance: Flutter volvió a agregar exclusiones a `analysis_options.yaml` durante las verificaciones; se descartó ese cambio ajeno al PR. La página `MyAccommodationsPage` sigue leyendo el almacén anterior y su migración pertenece al PR de Emmanuel. La compilación web y las pruebas de recreación no equivalen a una prueba manual de cierre y reapertura en navegador.
- Este PR prepara la API compartida; filtros, Dismissible y Deshacer de las dos pantallas siguen en los PR de cada grupo. No se atribuyen esos criterios a esta rama.

## 2026-11-04 - Recuperación de inicialización fallida (revisión del PR #34)

- Retroalimentación humana: el grupo detectó que el `Future` de inicialización quedaba fallido permanentemente si fallaba la primera lectura o la escritura de la siembra. La suite anterior no cubría esos dos caminos.
- Corrección: la inicialización ahora empieza al primer uso, comparte un solo `Future` entre llamadas simultáneas y lo libera si falla. El siguiente uso reintenta en la misma instancia. El estado de la siembra se publica únicamente después de confirmar su escritura; los fallos no emiten revisiones.
- Pruebas agregadas: recuperación tras lectura inicial fallida; recuperación tras escritura inicial fallida, comprobando que no queda dato guardado, que no hay revisiones y que una instancia nueva no duplica la siembra; consultas simultáneas comparten una sola inicialización.
- Verificación tras la corrección: contrato aislado, 13 pruebas aprobadas; `dart format --output=none --set-exit-if-changed lib test`, 45 archivos y 0 cambios; `flutter analyze --no-pub`, sin problemas; `flutter test --no-pub --reporter expanded`, 35 pruebas aprobadas; `flutter build web --no-pub`, `Built build/web` con código 0. Pendiente el CI remoto del PR actualizado.

## 2026-11-05 - Kenneth: integracion persistente y diagnostico web

- Herramienta: Codex. Rama aislada codex/28-integracion-almacenamiento; main y feat/28-filtro no se modificaron. Se integro el contenido del PR #34 (09381fa) en esta rama de preparacion, sin hacer merge del PR en GitHub. El incremental de Roberth 9ae84a5 se incorporo una sola vez como fca1a38.
- Composicion real: CatalogReader consulta el repositorio compartido; el controlador de borrado recibe deleteById y restore con el DeletedAccommodation original. Agregar y catalogo comparten instancia. Los providers declaran sus dependencias de scope para que las sustituciones de pruebas lleguen a los consumidores.
- Cuatro pruebas nuevas usan la implementacion persistente real con backend de preferencias controlado: borrado/restauracion y fallo/reintento, fallo de escritura sin retirar datos, recreacion sin resembrar y alta compartida. Se corrigio el desmontaje del harness antes de cerrar el repositorio; no se eliminaron aserciones para ocultar fallos.
- Verificacion: 83 pruebas aprobadas, flutter analyze sin problemas, compilacion web --no-pub --no-web-resources-cdn aprobada. Aviso de fuente Cupertino no bloqueante. Formato aplicado a los tres archivos senalados. No se afirma CI remoto de esta rama.
- Prueba manual automatizada con Playwright en perfil propio persistente y origen fijo http://127.0.0.1:8093: publicacion desde formulario de Casa S15 Integracion, precio 1000; aparece en catalogo. Despues de recargar y de cerrar/reabrir completamente el navegador permanece el registro owner-1793884789486000, sequence 3, con los mismos datos. Consola: cero errores y advertencias. Se uso compilacion release con recursos locales; no se reprodujo ni se determino la causa de la pantalla blanca reportada bajo flutter run.
- Pendientes: Mis alojamientos aun usa OwnerAccommodationStore; no se declara sincronizacion completa. La operacion para incorporar origin/feat/29-filtro fue rechazada en el control de permisos y no se ejecuto. No se recreo el trabajo de Emmanuel ni se sorteo ese rechazo. Las siete pruebas de Victor aun no estan incorporadas. PR #34 sigue abierto. No se cerraron issues ni se hizo merge a main.

## 2026-11-04 - Issue #29: contrato y filtro aislado

- Herramienta: Codex.
- Solicitud: implementar el listado del grupo #2 en `feat/29-filtro`, respetando la coordinación del grupo #1.
- Inspección: `README.md`, `docs/architecture.md`, `docs/state-and-data.md`, código de `MyAccommodationsPage`, `OwnerAccommodationStore`, alta y catálogo; issues #27, #28 y #29; historial y estado local/remoto de `main`.
- Confirmación GitHub: `main` apunta al merge 58166bf del PR #30. Rama local `feat/29-filtro` creada desde ese commit.
- Estado compartido: #27 no tiene comentarios con acuerdo de almacenamiento. El store actual solo agrega en memoria, usa tipo de texto y carece de consulta filtrada, borrado y restauración.
- Contrato propuesto en `owner_accommodation_repository.dart`: consulta asíncrona filtrada por `AccommodationType?`; borrar por id y confirmar solo al persistir; restaurar el objeto completo con el mismo id de forma idempotente; catálogo y listado leen la misma fuente de verdad. No se publicó comentario en GitHub.
- Implementación aislada: filtro inmutable con igualdad, Notifier Riverpod y FutureProvider dependiente de `ref.watch` del filtro y contrato inyectable. Se añadieron pruebas de igualdad, no reconsulta con el mismo filtro, consulta al cambiar, recuperación ante error y protección ante respuesta tardía.
- Propuesta descartada: adaptar ahora `OwnerAccommodationStore` o `ResultsPage` unilateralmente. El issue #29 exige acuerdo primero y ambas piezas son compartidas con el grupo #1; la implementación queda aislada hasta acordar.
- Limitaciones: los adjuntos `Lab4 D.pdf` y retroalimentación docente no estaban disponibles en el workspace en esta sesión. No se afirma persistencia tras reinicio; el store existente es solo memoria.
- Pendiente: acuerdo en #27; adaptador persistente compatible con web; UI del listado, Deshacer y pruebas de widgets/integración; validaciones Flutter y entrega/PR.

### Validación local del avance aislado

- Corrección: se reemplazaron imports relativos de `lib/` por imports `package:` después de que `flutter analyze` señaló esos avisos. La ejecución inicial también regeneró `pubspec.lock` y añadió exclusiones automáticas en `analysis_options.yaml`; ambos archivos se restauraron sin conservar cambios.
- Formato: `dart format --output=none --set-exit-if-changed` en los cuatro archivos Dart nuevos, 0 cambios pendientes.
- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 21 pruebas aprobadas, incluyendo 4 nuevas de filtro/provider.
- `flutter build web --no-pub`: finalizado correctamente. Flutter mostró los avisos existentes de `CupertinoIcons` no incluida y recomendación del dry run WASM; no se cambió `pubspec` para silenciarlos.
- Estas comprobaciones cubren solo el avance aislado; no acreditan aún UI de Mis alojamientos, borrado/Deshacer, persistencia, sincronización del catálogo ni cumplimiento total del issue #29.
- Ampliación del chequeo de formato: `dart format --output=none --set-exit-if-changed lib test`, 40 archivos, 0 cambios.

## 2026-11-04 - Issue #29: UI aislada de Mis alojamientos

- Implementación: `MyAccommodationsPage` ahora usa Riverpod y el provider dependiente del filtro; agrega Todos/Apartamento/Pensionado, estado de carga, error con Reintentar, vacío sin publicaciones con acción Agregar y vacío filtrado con acción Limpiar. Se conservan las tarjetas y se actualiza la consulta al volver de publicar.
- Adaptación temporal: se agregó `OwnerAccommodationStoreReadAdapter`, de solo lectura, sin editar `OwnerAccommodationStore`. Mapea el tipo al enum del dominio y consulta los registros existentes. Borrar/restaurar lanzan `UnsupportedError` hasta el acuerdo de #27; no se ofrecen acciones de borrado todavía.
- Pruebas widget nuevas con repositorio falso: carga/datos, filtro y visibilidad, vacío inicial/Agregar, vacío por filtro/Limpiar y error/Reintentar.
- `dart format --output=none --set-exit-if-changed lib test`: 42 archivos, 0 cambios.
- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 26 pruebas aprobadas.
- `flutter build web --no-pub`: finalizado correctamente; Flutter mostró el aviso WASM dry run y la referencia existente a `CupertinoIcons` sin asset.
- Pendiente de coordinación: no se modificaron catálogo ni almacenamiento compartido. El adaptador sigue siendo temporal/en memoria y no acredita persistencia al cerrar y abrir la app. Esperar acuerdo de #27 para implementar CRUD durable y sincronización del mismo origen de datos con el catálogo.
- Corrección de integración de altas: al crear una nueva instancia de la página se invalida la consulta para incluir publicaciones hechas previamente desde el panel; volver de Agregar también invalida la consulta. La reconstrucción de la página no invalida el provider.
- Validación tras este ajuste: formato global `lib test` (42 archivos, 0 cambios), análisis sin problemas, suite completa (26 aprobadas) y compilación web completada. `git diff --check` limpio; sin commit ni PR.
