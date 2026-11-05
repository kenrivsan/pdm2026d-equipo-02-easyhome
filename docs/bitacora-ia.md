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
