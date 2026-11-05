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

## 2026-11-04 - QA de aceptacion issue #28 - Victor

- Herramienta utilizada: ChatGPT.
- Se revisaron los componentes del PR #32 y el contrato del PR #34.
- Se prepararon 7 pruebas de aceptacion con fuente controlada.
- Resultado individual: 7 pruebas aprobadas.
- Suite completa: 49 pruebas aprobadas.
- flutter analyze: sin problemas.
- flutter build web: compilacion exitosa.
- git diff --check: sin errores.
- No se modificaron ResultsPage ni el almacenamiento.
- Pendiente: validar integracion y persistencia real.
- Las pruebas no certifican aun el issue #28 completo.
