import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_deletion_controller.dart';

/// Capacidad de escritura inyectada por la composición de la app.
/// null mantiene el catálogo en modo lectura mientras se integra el repositorio
/// compartido. No se fabrica un borrado local para sustituir la persistencia.
final catalogDeletionControllerProvider =
    Provider<CatalogDeletionController<Object>?>(
      (ref) => null,
      dependencies: const [],
    );
