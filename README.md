# Easy Home

## Descripción

Easy Home es una aplicación orientada a estudiantes universitarios que busca facilitar la búsqueda de apartamentos y pensionados cercanos a su universidad, permitiendo consultar opciones disponibles, aplicar filtros y revisar información relevante de cada alojamiento.

## Usuario objetivo y problema

**Usuario objetivo:** estudiantes universitarios que buscan apartamentos o pensionados relativamente cerca de su universidad.

**Problema:** los estudiantes tienen dificultad para encontrar alojamientos disponibles, no siempre saben qué lugares ofrecen apartamentos o pensionados, desconocen cómo son las instalaciones por dentro y, en algunos casos, las ubicaciones disponibles no son suficientemente precisas.

## Flujo principal del MVP

El estudiante ingresa a Easy Home, selecciona el departamento geográfico donde estudiará y su universidad, revisa apartamentos o pensionados cercanos, selecciona una opción de interés y consulta su disponibilidad, ubicación, imágenes, características e información de contacto del encargado.

## Alcance del MVP

- Buscar apartamentos o pensionados disponibles dentro de un departamento geográfico específico.
- Visualizar información detallada de cada opción, incluyendo ubicación, disponibilidad, cantidad de baños, tamaño, imágenes e información de contacto del encargado.
- Filtrar los resultados según el tipo de alojamiento —apartamento o pensionado— y una ubicación específica.

## Fuera del alcance por ahora

- Chat interno para la comunicación entre estudiantes y encargados.
- Sistema de reseñas y calificaciones de apartamentos o pensionados.
- Notificaciones sobre nuevos alojamientos relacionados con universidades o ubicaciones buscadas previamente.

## Roles de esta semana

Los roles son rotativos y pueden cambiar en cada etapa del proyecto. Todos los integrantes participan en el desarrollo.

| Integrante | Usuario GitHub | Rol |
|---|---|---|
| Kenneth Rivera | @kenrivsan | Arquitectura |
| Emmanuel | @EmmanuelC-04 | Producto / PM |
| Javier Sontay | @Javiersontay | UX / Investigación |
| Víctor de León | @victordeleon172003 | QA |
| Roberth | @roberdeleon | Release |

## Flujo de trabajo en GitHub

Todo cambio debe seguir el siguiente flujo:

**Issue → Rama → Pull Request → Revisión → Merge**

Reglas de trabajo:

- Todo cambio debe comenzar desde un issue.
- Cada issue debe trabajarse en una rama independiente.
- Los cambios deben integrarse mediante un Pull Request.
- Otro integrante debe revisar el Pull Request antes de hacer merge.
- No se realizan cambios directamente sobre la rama `main`.

## Estructura inicial del proyecto

La aplicación usa una arquitectura **feature-first con capas**. La decisión, las responsabilidades y las convenciones para agregar funcionalidades están documentadas en [`docs/architecture.md`](docs/architecture.md).

La funcionalidad de alojamientos ya cuenta con la separación base entre `presentation`, `domain` y `data`, lista para incorporar búsqueda, filtros, listado y detalle sin mezclar responsabilidades.
