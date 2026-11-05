import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/accommodations/data/owner_accommodation_store.dart';
import '../features/accommodations/data/repositories/current_catalog_reader.dart';
import '../features/accommodations/domain/entities/catalog_filter.dart';
import '../features/accommodations/domain/repositories/accommodation_repository.dart';
import '../features/accommodations/presentation/controllers/catalog_providers.dart';

/// Único punto para sustituir el adaptador del MVP por el compartido definitivo.
class CatalogScope extends StatefulWidget {
  const CatalogScope({
    required this.repository,
    required this.child,
    this.initialFilter = const CatalogFilter(),
    super.key,
  });

  final AccommodationRepository repository;
  final CatalogFilter initialFilter;
  final Widget child;

  @override
  State<CatalogScope> createState() => _CatalogScopeState();
}

class _CatalogScopeState extends State<CatalogScope> {
  // Se conservan los overrides entre rebuilds para no recrear el lector.
  late final _overrides = [
    catalogReaderProvider.overrideWith((ref) {
      final reader = CurrentCatalogReader(
        widget.repository,
        OwnerAccommodationStore.instance,
      );
      ref.onDispose(reader.dispose);
      return reader;
    }),
    catalogFilterProvider.overrideWith(
      () => CatalogFilterNotifier(widget.initialFilter),
    ),
  ];

  @override
  Widget build(BuildContext context) => ProviderScope(
    key: ObjectKey(widget.repository),
    overrides: _overrides,
    child: widget.child,
  );
}
