## Problema y resultado

## Issue relacionado
Closes #

## Grupo y alcance
<!-- Grupo 1 / Grupo 2 / navegación compartida. Identificar el listado. -->

## Cómo probar
1.
2.

## Evidencia de rúbrica S15
- [ ] Navegación: pestaña en Notifier, IndexedStack, navegación desde otra pantalla y scroll conservado.
- [ ] Filtro inmutable en Notifier; provider de lista usa ref.watch del filtro y vuelve a consultar solo al cambiarlo.
- [ ] Listado: cargando, error con Reintentar, vacío según filtro y datos.
- [ ] Dismissible con key basada en id; borrado confirmado por repositorio y fila recuperada al fallar.
- [ ] Deshacer restaura mismo id y todos los datos; se maneja fallo de restauración.
- [ ] Widget test del filtro y de borrar/Deshacer.
- [ ] Verificación al cerrar y abrir la aplicación.
<!-- Marcar N/A y justificar lo ajeno al alcance; no marcar evidencia no verificada. -->

## Validación realizada
<!-- Copiar comandos y resultados reales; adjuntar capturas o video. -->
- [ ] dart format --output=none --set-exit-if-changed lib test
- [ ] flutter analyze
- [ ] flutter test
- [ ] CI de este PR en verde (adjuntar enlace).
- [ ] Uso de IA, correcciones y rechazos en docs/bitacora-ia.md.

## Pregunta obligatoria de S15
¿Por qué la key del Dismissible debe ser el id y no el índice, y qué pasaría si se borrara la fila 2 de 5?
<!-- Responder con el comportamiento concreto; no dejar esta sección vacía. -->

## Revisión de la otra pareja/grupo
<!-- Enlace a la revisión humana. No reemplazarla con una revisión de IA. -->
