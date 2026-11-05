# Issue #28 — Borrado y Deshacer de Roberth

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

La suite utiliza un falso que emite cambios únicamente después de escribir; también emite antes de devolver el Future, para cubrir esa carrera con la reconstrucción de la lista. Compilación web y CI se documentan con sus resultados reales al concluir.

Pendientes de integración: API y PR de Javier, conexión de Kenneth, revisión humana del grupo #2, pruebas reales de sincronización con publicaciones de propietarios y cierre/reapertura de la aplicación por Víctor. Estos criterios generales de #28 no se marcan como cumplidos en esta preparación.
