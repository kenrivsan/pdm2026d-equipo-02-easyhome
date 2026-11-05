import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/accommodation.dart';
import '../../domain/entities/catalog_filter.dart';
import '../../domain/repositories/catalog_reader.dart';

/// CatalogScope inyecta el lector del repositorio actual del MVP.
/// Se sustituirá por el adaptador compartido al publicar su contrato definitivo.
final catalogReaderProvider = Provider<CatalogReader>((ref) {
  throw StateError('Falta inyectar el lector del catálogo compartido.');
});

final catalogFilterProvider =
    NotifierProvider<CatalogFilterNotifier, CatalogFilter>(
      CatalogFilterNotifier.new,
    );

class CatalogFilterNotifier extends Notifier<CatalogFilter> {
  CatalogFilterNotifier([this.initialFilter = const CatalogFilter()]);

  final CatalogFilter initialFilter;

  @override
  CatalogFilter build() => initialFilter;

  void setFilter(CatalogFilter filter) {
    if (state != filter) state = filter;
  }

  void selectType(AccommodationType? type) => setFilter(state.withType(type));

  /// El llamador valida la universidad contra el departamento seleccionado.
  /// Omitir universityId limpia una selección anterior incompatible.
  void selectLocation({String? departmentId, String? universityId}) =>
      setFilter(
        state.withLocation(
          departmentId: departmentId,
          universityId: universityId,
        ),
      );

  void clear() => setFilter(const CatalogFilter());
}

final _catalogRevisionProvider = NotifierProvider<_CatalogRevision, int>(
  _CatalogRevision.new,
);

class _CatalogRevision extends Notifier<int> {
  @override
  int build() {
    final subscription = ref.watch(catalogReaderProvider).changes.listen((
      revision,
    ) {
      if (revision > state) state = revision;
    });
    ref.onDispose(() => unawaited(subscription.cancel()));
    return 0;
  }
}

final catalogResultsProvider = FutureProvider<List<Accommodation>>((ref) async {
  final filter = ref.watch(catalogFilterProvider);
  final reader = ref.watch(catalogReaderProvider);
  ref.watch(_catalogRevisionProvider);
  return List.unmodifiable(await reader.query(filter));
  // Reintentar es explícito: un error no provoca consultas ocultas con backoff.
}, retry: (_, _) => null);
