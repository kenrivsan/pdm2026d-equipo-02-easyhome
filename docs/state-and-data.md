# Estado y acceso a datos durante M1

## Decisión

Easy Home utilizará `Provider` con un `ChangeNotifier` por funcionalidad durante M1. La primera implementación es `AccommodationSearchController`, responsable del estado compartido de búsqueda, filtros y alojamientos disponibles.

Los datos se obtienen temporalmente de fuentes en memoria. No se conecta una base de datos ni una API remota en este issue.

## Flujo de dependencias

```text
AccommodationsPage
        │ observa y envía acciones
        ▼
AccommodationSearchController
        │ depende de contratos del dominio
        ├── AccommodationRepository
        └── LocationRepository
                 │
                 ▼
        Implementaciones de data
                 │
                 ▼
        Fuentes temporales en memoria
```

Las pantallas no importan modelos de `data` ni consultan directamente una fuente. Esto permitirá sustituir los datos en memoria por una API o base de datos sin reescribir la interfaz.

## Estado compartido

El controlador mantiene:

- departamentos y universidades disponibles;
- departamento y universidad seleccionados;
- tipo de alojamiento seleccionado;
- alojamientos cargados y resultados filtrados;
- estado de carga y mensaje de error.

Solo se muestran alojamientos con `available == true`. Los filtros se combinan por departamento, universidad y tipo.

Al seleccionar una universidad, su departamento queda seleccionado. Si luego se cambia a otro departamento, la universidad incompatible se limpia.

## Navegación a detalle

La futura ruta de detalle recibirá únicamente el ID del alojamiento. La pantalla podrá resolverlo con `findAccommodationById`, evitando guardar una segunda copia del alojamiento seleccionado.

## Límites de esta decisión

- Los datos incluidos son ficticios y sirven únicamente para desarrollar M1.
- No se implementan persistencia, caché, autenticación ni backend.
- Las pantallas completas de búsqueda, filtros, listado y detalle pertenecen a sus propios issues.
- Si el estado aumenta significativamente después de M1, el equipo reevaluará la estrategia antes de migrar a otra solución.
