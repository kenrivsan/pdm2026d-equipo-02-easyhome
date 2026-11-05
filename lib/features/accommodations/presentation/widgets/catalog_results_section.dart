import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/accommodation.dart';
import '../controllers/catalog_providers.dart';

/// Estados del catálogo, independientes de la tarjeta y del almacenamiento.
/// ResultsPage podrá conservar su tarjeta y navegación actuales al integrarlo.
class CatalogResultsSection extends ConsumerWidget {
  const CatalogResultsSection({required this.itemBuilder, super.key});

  final Widget Function(BuildContext, Accommodation) itemBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(catalogResultsProvider);
    return results.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (_, _) => Column(
            children: [
              const Text('No fue posible cargar los alojamientos.'),
              FilledButton(
                onPressed: () => ref.invalidate(catalogResultsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
      data: (items) {
        if (items.isEmpty) {
          final hasFilter = !ref.watch(catalogFilterProvider).isEmpty;
          return Column(
            children: [
              const Text(
                'No se encontraron alojamientos disponibles para esta búsqueda.',
              ),
              if (hasFilter)
                TextButton(
                  onPressed: ref.read(catalogFilterProvider.notifier).clear,
                  child: const Text('Limpiar filtros'),
                ),
            ],
          );
        }
        return Column(
          children: [for (final item in items) itemBuilder(context, item)],
        );
      },
    );
  }
}
