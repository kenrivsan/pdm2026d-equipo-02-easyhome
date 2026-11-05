import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/accommodations/domain/entities/deleted_accommodation.dart';
import '../features/accommodations/presentation/controllers/catalog_deletion_controller.dart';
import '../features/accommodations/presentation/providers/shared_accommodation_providers.dart';

/// Capacidad de Mis alojamientos, inyectada por EasyHomeApp.
/// Cada pantalla tiene su propio controller y host; ambas escriben en el mismo
/// repositorio. El provider tambien permite montar la pantalla aisladamente.
final ownerAccommodationDeletionControllerProvider =
    Provider<CatalogDeletionController<Object>>(
      createSharedAccommodationDeletionController,
      dependencies: const [],
    );

/// Se invoca por separado para cada provider de pantalla. No compartir una
/// instancia de controller entre hosts: sus tickets y mensajes son independientes.
CatalogDeletionController<Object> createSharedAccommodationDeletionController(
  Ref ref,
) {
  final repository = ref.watch(sharedAccommodationRepositoryProvider);
  final controller = CatalogDeletionController<Object>(
    deleteById: repository.deleteById,
    restore: (snapshot) => repository.restore(snapshot as DeletedAccommodation),
  );
  ref.onDispose(controller.dispose);
  return controller;
}
