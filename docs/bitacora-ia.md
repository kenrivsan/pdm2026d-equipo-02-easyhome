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
