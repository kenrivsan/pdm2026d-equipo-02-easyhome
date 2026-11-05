# Bitácora de uso de IA

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
