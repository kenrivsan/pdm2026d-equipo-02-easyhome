import 'dart:async';

import 'package:easyhome/features/accommodations/data/datasources/accommodation_data_source.dart';
import 'package:easyhome/features/accommodations/data/datasources/location_data_source.dart';
import 'package:easyhome/features/accommodations/data/repositories/accommodation_repository_impl.dart';
import 'package:easyhome/features/accommodations/data/repositories/location_repository_impl.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/entities/catalog_filter.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/accommodation_search_controller.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_deletion_controller.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_deletion_provider.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_providers.dart';
import 'package:easyhome/features/accommodations/presentation/pages/results_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/fake_catalog_reader.dart';

/// Snapshot exclusivo de pruebas: el controlador lo transporta como objeto
/// opaco. La integración definitiva usará el DeletedAccommodation del PR #34.
class _Snapshot {
  const _Snapshot(this.record);
  final Accommodation record;
}

class _ControlledCatalog extends FakeCatalogReader {
  final items = [...FakeCatalogReader.fixtures];
  final deletions = <_Snapshot>[];
  final restored = <Object>[];
  final deleteCalls = <String>[];
  bool failDelete = false;
  bool failRestore = false;
  bool failReadOnce = false;
  Completer<void>? deleteGate;
  int revision = 0;

  @override
  Future<List<Accommodation>> query(CatalogFilter filter) async {
    queries.add(filter);
    if (failReadOnce) {
      failReadOnce = false;
      throw Exception('Lectura simulada fallida');
    }
    return items
        .where(
          (item) =>
              item.available &&
              (filter.type == null || item.type == filter.type) &&
              (filter.departmentId == null ||
                  item.departmentId == filter.departmentId) &&
              (filter.universityId == null ||
                  item.universityIds.contains(filter.universityId)),
        )
        .toList();
  }

  Future<Object> deleteById(String id) async {
    deleteCalls.add(id);
    if (deleteGate != null) await deleteGate!.future;
    if (failDelete) throw Exception('Borrado simulado fallido');
    final record = items.singleWhere((item) => item.id == id);
    final snapshot = _Snapshot(record);
    deletions.add(snapshot);
    items.remove(record);
    changesController.add(++revision);
    return snapshot;
  }

  Future<void> restore(Object value) async {
    restored.add(value);
    if (failRestore) throw Exception('Restauración simulada fallida');
    final snapshot = value as _Snapshot;
    if (items.any((item) => item.id == snapshot.record.id)) {
      throw StateError('Duplicado');
    }
    items.add(snapshot.record);
    items.sort(
      (a, b) => FakeCatalogReader.fixtures
          .indexOf(a)
          .compareTo(FakeCatalogReader.fixtures.indexOf(b)),
    );
    changesController.add(++revision);
  }
}

void main() {
  late _ControlledCatalog source;
  late AccommodationSearchController search;
  late CatalogDeletionController<Object> deletion;

  setUp(() async {
    source = _ControlledCatalog();
    search = AccommodationSearchController(
      accommodationRepository: AccommodationRepositoryImpl(
        InMemoryAccommodationDataSource(),
      ),
      locationRepository: LocationRepositoryImpl(InMemoryLocationDataSource()),
    );
    await search.loadData();
    deletion = CatalogDeletionController<Object>(
      deleteById: source.deleteById,
      restore: source.restore,
    );
  });
  tearDown(() async {
    deletion.dispose();
    search.dispose();
    await source.close();
  });

  Future<void> mount(WidgetTester tester, {bool writable = true}) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: search,
        child: ProviderScope(
          overrides: [
            catalogReaderProvider.overrideWithValue(source),
            if (writable)
              catalogDeletionControllerProvider.overrideWithValue(deletion),
          ],
          child: const MaterialApp(home: ResultsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> swipe(WidgetTester tester, String id) async {
    final row = find.byWidgetPredicate(
      (widget) => widget is Dismissible && widget.key == ValueKey(id),
    );
    await tester.ensureVisible(row);
    await tester.drag(row, const Offset(-700, 0));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
    'deslizar y Deshacer desde ResultsPage conserva snapshot, datos y orden',
    (tester) async {
      await mount(tester);
      final original = source.items.first;
      await swipe(tester, original.id);
      await tester.pumpAndSettle();
      expect(find.text(original.title), findsNothing);
      expect(find.text('Deshacer'), findsOneWidget);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(source.restored.single, same(source.deletions.single));
      expect(source.items.first, same(original));
      expect(source.items.map((item) => item.id), [
        'apartment-1',
        'boarding-1',
      ]);
      expect(find.text(original.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fallo de borrado mantiene tarjeta y permite reintentar el gesto',
    (tester) async {
      await mount(tester);
      source.failDelete = true;
      await swipe(tester, 'apartment-1');
      await tester.pumpAndSettle();
      expect(find.text('Apartamento de prueba'), findsOneWidget);
      expect(find.text('No se pudo borrar el alojamiento.'), findsOneWidget);
      expect(deletion.isLocked('apartment-1'), isFalse);
      expect(source.deletions, isEmpty);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      source.failDelete = false;
      await swipe(tester, 'apartment-1');
      await tester.pumpAndSettle();
      expect(find.text('Apartamento de prueba'), findsNothing);
      expect(find.text('Deshacer'), findsOneWidget);
    },
  );

  testWidgets('restauración fallida ofrece Reintentar con el mismo snapshot', (
    tester,
  ) async {
    await mount(tester);
    await swipe(tester, 'apartment-1');
    await tester.pumpAndSettle();
    source.failRestore = true;
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo restaurar el alojamiento.'), findsOneWidget);
    expect(find.text('Apartamento de prueba'), findsNothing);
    source.failRestore = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Apartamento de prueba'), findsOneWidget);
    expect(source.restored, hasLength(2));
    expect(source.restored.first, same(source.restored.last));
    expect(
      source.items.where((item) => item.id == 'apartment-1'),
      hasLength(1),
    );
  });

  testWidgets('espera confirmación y bloquea borrado repetido', (tester) async {
    await mount(tester);
    source.deleteGate = Completer<void>();
    await swipe(tester, 'apartment-1');
    expect(find.text('Apartamento de prueba'), findsOneWidget);
    expect(source.items, hasLength(2));
    await swipe(tester, 'apartment-1');
    expect(source.deleteCalls, ['apartment-1']);
    source.deleteGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Apartamento de prueba'), findsNothing);
    expect(find.text('Deshacer'), findsOneWidget);
  });

  testWidgets(
    'cambiar filtro durante escritura conserva Deshacer y respeta el filtro',
    (tester) async {
      await mount(tester);
      source.deleteGate = Completer<void>();
      await swipe(tester, 'apartment-1');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ResultsPage)),
      );
      container
          .read(catalogFilterProvider.notifier)
          .selectType(AccommodationType.boardingHouse);
      await tester.pumpAndSettle();
      source.deleteGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Deshacer'), findsOneWidget);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(source.items, hasLength(2));
      expect(find.text('Apartamento de prueba'), findsNothing);
      expect(find.text('Pensionado de prueba'), findsOneWidget);
      expect(
        container.read(catalogFilterProvider).type,
        AccommodationType.boardingHouse,
      );
    },
  );

  testWidgets(
    'dos borrados consecutivos tienen oportunidades independientes de Deshacer',
    (tester) async {
      await mount(tester);
      await swipe(tester, 'apartment-1');
      await tester.pumpAndSettle();
      await swipe(tester, 'boarding-1');
      await tester.pumpAndSettle();
      expect(source.items, isEmpty);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(source.restored, hasLength(2));
      expect(source.items.map((item) => item.id), [
        'apartment-1',
        'boarding-1',
      ]);
    },
  );

  testWidgets('un error de consulta no destruye el host de Deshacer', (
    tester,
  ) async {
    await mount(tester);
    source.failReadOnce = true;
    await swipe(tester, 'apartment-1');
    await tester.pumpAndSettle();
    expect(
      find.text('No fue posible cargar los alojamientos.'),
      findsOneWidget,
    );
    expect(find.text('Deshacer'), findsOneWidget);
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(find.text('Apartamento de prueba'), findsOneWidget);
    expect(source.items, hasLength(2));
  });

  testWidgets('una fuente sin escritura conserva el catálogo de lectura', (
    tester,
  ) async {
    await mount(tester, writable: false);
    expect(find.byType(Dismissible), findsNothing);
    expect(find.text('Apartamento de prueba'), findsOneWidget);
    expect(source.deleteCalls, isEmpty);
  });
}
