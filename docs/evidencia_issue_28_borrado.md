# Issue #28 — Borrado y Deshacer de Roberth

## Revisión de la conexión de Kenneth — 2026-11-04

Se revisó #33 en `343446f62cb18f60672f4469040c2aac556e056f`. Los commits originales de #32 (`daa2bd5`, `87e62d3`) ya son ancestros de esa integración: no se repiten, copian ni integran por otro PR. La corrección posterior se entrega como un solo commit incremental en `feat/28-borrado-deshacer`; Kenneth podrá incorporarlo una vez, conservando autoría. #32 queda como origen/evidencia y #33 como vía de integración del catálogo. No se cierran PR/issues ni se realiza merge.

**Conexión revisada:** ResultsPage obtiene un controller de un provider independiente del filtro. CatalogUndoHost envuelve el Scaffold completo, sin key asociada al filtro, fuera de CatalogResultsSection y sus ramas cargando/error/vacío/datos. Las tarjetas y el Dismissible conservan ID estable. El host permanece mientras la capacidad de escritura y su controller sean los mismos; por defecto el provider sigue en null (solo lectura). Los cambios de filtro o de estado de consulta no cambian ese provider. No se editó ResultsPage ni el provider de Kenneth.

Coordinación de archivos antes de corregir: https://github.com/kenrivsan/pdm2026d-equipo-02-easyhome/pull/33#issuecomment-6650302698. Se reservaron únicamente controller, pruebas propias y estos documentos en la rama de Roberth. La validación combinada usa una copia local separada, sin publicar en la rama de Kenneth ni añadir sus commits a #32.

**Problema reproducido y corregido:** el stream broadcast descartaba el aviso si el host ya no tenía suscripción. Un borrado terminado tras desmontar, una restauración fallida tras desmontar y la cancelación entre encolar/entregar el evento dejaban el ID bloqueado. Antes del arreglo fallaron las tres comprobaciones. El controller ahora abandona tickets sin consumidor y libera sus IDs, incluso si la cancelación sucede antes de entregar un evento encolado. Una restauración en curso conserva el bloqueo hasta terminar, para evitar otra escritura. Si se remonta el host antes de fallar, recibe Reintentar con el mismo snapshot. Salir no restaura datos, no cancela escrituras ni anuncia éxito falso.

Validación local (Flutter 3.47.7 / Dart 3.13.5):

| Escenario | Resultado |
|---|---|
| #33 original: results_page_deletion_integration_test.dart | 8 pruebas aprobadas |
| Rama propia con corrección, suite completa | 36 pruebas aprobadas: 21 previas + 15 de componentes |
| #33 + únicamente controller/pruebas corregidos en copia separada, suite completa | 65 pruebas aprobadas (62 originales + 3 nuevas) |
| Regresiones nuevas/ampliadas | Borrado tardío sin host; restauración fallida sin host; cancelación antes de entregar; remontaje durante restauración con mismo snapshot |
| Formato | Rama propia: 41 archivos, 0 cambios; copia combinada: 56 archivos, 0 cambios |
| Análisis | Sin problemas en rama propia y copia combinada |

Se conserva el comportamiento verificado de confirmación lenta/doble gesto, errores, Reintentar, borrados consecutivos, filtro durante escritura, expiración y ausencia de duplicados. Se amplió una prueba existente de desmontaje y se añadieron tres pruebas; no se fabricó otra implementación de los componentes.

### Conexión real pendiente de #34

#34 sigue **abierto, sin integrar**, en `09381fa875b455eee1ba1a40a642e8c4c16d3ee8`. Se revisó su contrato publicado y la retroalimentación de inicialización recuperable, corregida por ese commit. No se incorporó #34 ni se modificaron almacenamiento, dependencias o Mis alojamientos. La suite combinada anterior usa las fuentes de prueba de Kenneth; no certifica la persistencia real.

Después de integrar #34, Kenneth debe conectar un controller estable a `sharedAccommodationRepositoryProvider`: `deleteById` devuelve `Future<DeletedAccommodation>` y `restore` recibe ese mismo DeletedAccommodation (incluye record, deletionToken y sequence). Preferir el tipo concreto para provider/controller y ajustar juntos sus consumidores; no regenerar el snapshot desde Accommodation ni perder el token o sequence. Registrar dispose con el ciclo de vida del provider, sin depender del filtro ni de la revisión de lectura.

El lector de catálogo debe consultar `AccommodationQuery(type, departmentId, universityId, onlyOwned: false)`, delegar `changes` a la **misma instancia** del repositorio y proyectar `record.toAccommodation()` para las tarjetas. La consulta real no filtra por available: conservar la regla del catálogo estudiantil al adaptar sus resultados. Este punto se comunica a Kenneth, sin editar su adaptador. La lectura reactiva y los callbacks de escritura deben compartir instancia para que un borrado/restauración confirmado actualice la consulta vigente.

Revalidar tras esa integración: fallos reales de escritura e inicialización, snapshot exacto (incluye description/isOwned), orden con varios borrados, sincronización de publicaciones y persistencia al reiniciar. PDF S15/retroalimentación externa aún no disponibles localmente; las conclusiones se limitan al código, issues y revisiones accesibles. Las secciones siguientes preservan la evidencia de la preparación original de #32.

## Alcance y fuentes

Preparación aislada basada en `main` después de PR #30 y #31 (`2b1b8fa`). Se revisaron #27 (incluidas ambas aceptaciones del contrato), #28, las revisiones de los PR, el código actual, la evidencia preliminar de Víctor y los componentes de `feat/28-filtro` (`c72ee60`). No se modifican ResultsPage, OwnerAccommodationStore, dependencias ni persistencia. El PDF S15 y la retroalimentación externa no están disponibles en esta PC nueva, según confirmó el usuario; no se afirma haberlos leído.

Coordinación inicial publicada: https://github.com/kenrivsan/pdm2026d-equipo-02-easyhome/issues/28#issuecomment-6648562804. La propuesta requiere respuesta de Kenneth antes de editar su pantalla. No se cierra #28 ni se hace merge.

## Archivos y API de UI para Kenneth

- `presentation/controllers/catalog_deletion_controller.dart`: callbacks asíncronos `deleteById(String)` y `restore(S)`; `S` es el snapshot opaco devuelto por Javier. Conserva su identidad, sin reconstruir campos ni calcular índices.
- `presentation/widgets/catalog_dismissible.dart`: recibe `alojamiento`, `controller` y `child`; tanto el wrapper como Dismissible tienen `ValueKey(alojamiento.id)`.
- `presentation/widgets/catalog_undo_host.dart`: envolver el **Scaffold** de ResultsPage con este host. Proporciona un ScaffoldMessenger propio y conserva la cola fuera de las filas y los estados cargando/error/vacío. Crear el controller una sola vez durante la vida de la pantalla y disponerlo al salir; no recrearlo al filtrar. Usar exactamente un host por controller.
- `test/features/accommodations/presentation/widgets/catalog_deletion_test.dart`: falso aislado de pruebas, sin persistencia.

Cuando exista la API de Javier, instanciar `CatalogDeletionController<DeletedAccommodation>` con referencias a `repository.deleteById` y `repository.restore`, verificando firmas y tipos reales. No se declaran entidades alternativas llamadas AccommodationRecord o DeletedAccommodation. El componente actual acepta Accommodation para aprovechar las tarjetas existentes; si la entidad publicada es distinta, adaptar su proyección de lectura al integrar, sin usarla para fabricar snapshots.

En `CatalogResultsSection.itemBuilder`, Kenneth podrá envolver su tarjeta con `CatalogDismissible(alojamiento: item, controller: deletionController, child: tarjetaActual)`. Mantener el host por encima de esta sección. Esta es una propuesta de conexión, no código ya integrado.

## Confirmación, consulta y orden

`confirmDismiss` espera `deleteById`; no usa `onDismissed` para borrar datos. Devuelve false deliberadamente: la retirada de la fila corresponde a la consulta reactiva tras `changes` confirmado. Así la fila no desaparece por una animación antes de saber si la escritura tuvo éxito; tampoco queda un Dismissible descartado en el árbol cuando el provider se reconstruye. Si falla, se libera el bloqueo y se informa el error. No se filtra ni se mantiene una segunda copia local del catálogo.

**Requisito para integrar:** conectar la consulta a `changes` del repositorio compartido (según #27 y el puerto CatalogReader de la rama de filtros). No reutilizar una consulta en caché tras una revisión. Hasta conectar ese flujo, una escritura correcta podría dejar visible una fila antigua; el componente no finge sincronización. Cada consulta debe respetar el filtro vigente y el orden estable del repositorio.

Cada borrado confirmado tiene un ticket propio; los SnackBars se encolan y no se sustituyen. El ticket bloquea otra operación del mismo ID hasta restaurarlo o cerrar/expirar su aviso. Deshacer pasa exactamente el snapshot recibido. La restauración pendiente bloquea dobles clics; un ticket consumido, vencido o de otro controller no se ejecuta. Si falla, no se muestra éxito y el aviso permite Reintentar con el mismo snapshot. Descartar el aviso abandona esa oportunidad de Deshacer. Al salir de la pantalla se descartan los avisos de su messenger, no se revierten escrituras confirmadas.

ID, campos completos, orden estable, ausencia de duplicados, persistencia y atomicidad de los errores pertenecen al contrato del repositorio de Javier. Una posición dentro de la lista filtrada no representa el orden global. Las pruebas de UI verifican la delegación del snapshot completo; el falso no certifica el almacenamiento real ni el reinicio de la app.

## Por qué la key es el ID y no el índice

Si se borra la fila 2 de 5, las antiguas filas 3, 4 y 5 pasan a ocupar las posiciones 2, 3 y 4. Una key basada en índice puede reutilizar el estado o la animación de la tarjeta eliminada para otro alojamiento, e incluso asociar un descarte a la fila equivocada. `ValueKey(alojamiento.id)` sigue identificando el mismo registro al cambiar el orden, filtrar, borrar o restaurar.

## Casos ejecutables para Víctor

1. Escritura lenta: fila visible antes de confirmar; otro intento con el mismo ID no llama al repositorio otra vez.
2. Fallo al borrar: fila visible, mensaje de error, posibilidad de repetir.
3. Borrar fila 2 de 5 y Deshacer: mismo snapshot por identidad, todos los campos conservados y orden original.
4. Borrar 2 y 3 consecutivamente: dos oportunidades de Deshacer independientes; restauración correcta en ambos casos.
5. Cambiar filtro durante el SnackBar: restaura en el repositorio sin forzar la aparición de una fila que el filtro excluye.
6. Fallo al restaurar: ningún mensaje de éxito, fila ausente, Reintentar utiliza el mismo snapshot.
7. Expiración del SnackBar: no restaura, libera la operación.
8. Cambiar filtro mientras deleteById sigue pendiente: la fila se desmonta sin perder el aviso posterior ni usar su contexto destruido.
9. Restauración lenta y ticket ya usado: una sola escritura, sin duplicados.
10. Ticket ajeno o vencido: no escribe; desmontar el host mientras espera el borrado no genera excepciones.
11. Dos borrados se confirman fuera de orden: cada ticket conserva su ID y snapshot correctos.
12. Disponer el controller durante una escritura: termina sin notificaciones a UI destruida.

## Validación y pendientes

Validación local: Flutter 3.47.7 / Dart 3.13.5 (SDK ya instalado en la PC). El CI existente usa Flutter 3.44.8; debe validarse también allí. Se conservaron sin cambios pubspec.yaml, pubspec.lock y analysis_options.yaml; se descartaron las actualizaciones automáticas que hizo el SDK local.

| Comprobación | Resultado |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | 41 archivos, 0 cambios |
| `flutter analyze --no-pub` | Sin problemas |
| `flutter test --no-pub --reporter expanded` | 33 pruebas aprobadas: 21 previas y 12 nuevas |
| `flutter build web --no-pub` | Compilación correcta; aviso de CupertinoIcons preexistente |
| `git diff --check` | Sin errores |

La suite utiliza un falso que emite cambios únicamente después de escribir; también emite antes de devolver el Future, para cubrir esa carrera con la reconstrucción de la lista.

Entrega para revisión: https://github.com/kenrivsan/pdm2026d-equipo-02-easyhome/pull/32 (borrador). Los checks del PR conservan la evidencia de CI para cada revisión; el resultado final se enlaza allí. Esta documentación no certifica los criterios de integración pendientes.

Pendientes de integración: API y PR de Javier, conexión de Kenneth, revisión humana del grupo #2, pruebas reales de sincronización con publicaciones de propietarios y cierre/reapertura de la aplicación por Víctor. Estos criterios generales de #28 no se marcan como cumplidos en esta preparación.
