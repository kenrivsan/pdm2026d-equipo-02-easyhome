# Evidencia preliminar de pruebas — Issue #28 (catálogo estudiantil)

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

