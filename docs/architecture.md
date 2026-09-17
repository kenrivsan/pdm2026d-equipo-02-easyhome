# Estructura inicial de Easy Home

## Decisión

Se adopta una arquitectura **feature-first con capas**. Cada funcionalidad mantiene cerca sus pantallas, reglas de negocio y acceso a datos, evitando que el crecimiento del MVP convierta `lib/` en un conjunto de carpetas globales difíciles de mantener.

```text
lib/
├── main.dart                         # Punto de entrada y bootstrap
├── app/                              # Composición de la aplicación
│   ├── app.dart                       # MaterialApp, rutas globales y providers
│   └── theme/app_theme.dart           # Tema visual compartido
├── core/                             # Código transversal sin reglas de negocio
│   └── constants/                     # Constantes globales
├── shared/                           # Widgets/utilidades reutilizables entre features
└── features/
    └── accommodations/
        ├── data/                      # Models, datasources y repositorios concretos
        ├── domain/                    # Entidades y contratos de repositorio
        └── presentation/              # Pages, widgets y estado de UI
```

## Responsabilidades

- `presentation` solo coordina la interfaz y el estado de pantalla; no conoce detalles de HTTP o persistencia.
- `domain` contiene entidades y contratos estables. Es la referencia que usarán búsqueda, filtros y detalle.
- `data` adapta una fuente concreta (memoria, API o base local) al contrato del dominio.
- `core` y `shared` contienen únicamente piezas realmente transversales; una clase específica de una funcionalidad permanece dentro de su feature.

## Convenciones para el equipo

1. Una nueva funcionalidad se crea dentro de `lib/features/<nombre>/`.
2. Las clases se nombran por responsabilidad (`*_page.dart`, `*_model.dart`, `*_repository.dart`, `*_data_source.dart`).
3. Las dependencias apuntan hacia adentro: `presentation → domain`; `data → domain`. El dominio no importa Flutter ni implementaciones de datos.
4. Los cambios de cada issue se trabajan en una rama y se integran mediante Pull Request.

La fuente `InMemoryAccommodationDataSource` es temporal para permitir el desarrollo del MVP sin decidir todavía el backend. Se reemplazará en la capa `data` cuando se defina la persistencia.
