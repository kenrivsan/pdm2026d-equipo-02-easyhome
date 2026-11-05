import 'dart:async';

import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/entities/catalog_filter.dart';
import 'package:easyhome/features/accommodations/domain/repositories/catalog_reader.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_deletion_controller.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_providers.dart';
import 'package:easyhome/features/accommodations/presentation/widgets/catalog_dismissible.dart';
import 'package:easyhome/features/accommodations/presentation/widgets/catalog_filter_bar.dart';
import 'package:easyhome/features/accommodations/presentation/widgets/catalog_results_section.dart';
import 'package:easyhome/features/accommodations/presentation/widgets/catalog_undo_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// QA de integracion con una fuente controlada, sin almacenamiento real.
/// Requiere los componentes del PR #32 sobre feat/28-filtro (#33).
/// NO certifica SharedPreferencesAsync ni el reinicio de la aplicacion.
void main() {
  late _ControlledCatalog source;
  late CatalogDeletionController<_DeletedSnapshot> deletion;

  setUp(() {
    source = _ControlledCatalog();
    deletion = CatalogDeletionController<_DeletedSnapshot>(
      deleteById: source.deleteById,
      restore: source.restore,
    );
  });

  tearDown(() async {
    deletion.dispose();
    await source.dispose();
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogReaderProvider.overrideWithValue(source)],
        child: _CatalogQaHarness(deletion: deletion),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('QA01: el filtro y el gesto eliminan exactamente el ID visible', (
    tester,
  ) async {
    await mount(tester);
    await _selectType(tester, 'Apartamento');
    expect(_visibleIds(tester), ['a', 'c', 'e']);

    await _swipe(tester, 'c');
    await tester.pumpAndSettle();

    expect(source.deleteRequests, ['c']);
    expect(source.items.map((item) => item.id), ['a', 'b', 'd', 'e']);
    expect(_visibleIds(tester), ['a', 'e']);
    expect(source.queries.last.type, AccommodationType.apartment);
  });

  testWidgets('QA02: no retira la fila antes de confirmar escritura', (
    tester,
  ) async {
    source.deleteGate = Completer<void>();
    await mount(tester);

    await _swipe(tester, 'b');
    expect(source.deleteRequests, ['b']);
    expect(_visibleIds(tester), contains('b'));
    expect(source.items.map((item) => item.id), contains('b'));
    expect(find.text('Deshacer'), findsNothing);
    expect(deletion.isLocked('b'), isTrue);

    source.deleteGate!.complete();
    await tester.pumpAndSettle();
    expect(source.items.map((item) => item.id), isNot(contains('b')));
    expect(_visibleIds(tester), isNot(contains('b')));
    expect(find.text('Deshacer'), findsOneWidget);
  });

  testWidgets(
    'QA03: un borrado rechazado conserva la fila y permite repetirlo',
    (tester) async {
      source.failDelete = true;
      await mount(tester);

      await _swipe(tester, 'd');
      await tester.pumpAndSettle();
      expect(source.items.map((item) => item.id), contains('d'));
      expect(_visibleIds(tester), contains('d'));
      expect(find.text('No se pudo borrar el alojamiento.'), findsOneWidget);
      expect(deletion.isLocked('d'), isFalse);

      source.failDelete = false;
      await _swipe(tester, 'd');
      await tester.pumpAndSettle();
      expect(source.deleteRequests, ['d', 'd']);
      expect(_visibleIds(tester), isNot(contains('d')));
    },
  );

  testWidgets('QA04: Deshacer conserva ID, todos los campos y orden', (
    tester,
  ) async {
    final before = source.items.toList();
    await mount(tester);

    await _swipe(tester, 'b');
    await tester.pumpAndSettle();
    expect(source.items.map((item) => item.id), ['a', 'c', 'd', 'e']);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();

    expect(source.items.map((item) => item.id), ['a', 'b', 'c', 'd', 'e']);
    expect(source.restores.single, same(source.deletions.single));
    expect(source.restores.single.position, 1);
    for (var i = 0; i < before.length; i++) {
      // Los registros son inmutables: la identidad original garantiza todos
      // sus campos, incluidas listas, ubicacion y datos de contacto.
      expect(source.items[i], same(before[i]));
      _expectSameFields(source.items[i], before[i]);
    }
    expect(_visibleIds(tester), ['a', 'b', 'c', 'd', 'e']);
  });

  testWidgets('QA05: si restaurar falla, muestra Reintentar sin duplicar', (
    tester,
  ) async {
    await mount(tester);
    await _swipe(tester, 'c');
    await tester.pumpAndSettle();

    source.failRestore = true;
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo restaurar el alojamiento.'), findsOneWidget);
    expect(find.text('Alojamiento restaurado.'), findsNothing);
    expect(_visibleIds(tester), isNot(contains('c')));
    expect(deletion.isLocked('c'), isTrue);

    source.failRestore = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(source.restores, hasLength(2));
    expect(source.restores[0], same(source.restores[1]));
    expect(source.items.where((item) => item.id == 'c'), hasLength(1));
    expect(_visibleIds(tester), contains('c'));
    expect(deletion.isLocked('c'), isFalse);
  });

  testWidgets('QA06: borrados consecutivos y peticiones repetidas no duplican', (
    tester,
  ) async {
    await mount(tester);
    await _swipe(tester, 'b');
    await tester.pumpAndSettle();
    await _swipe(tester, 'c');
    await tester.pumpAndSettle();
    expect(source.items.map((item) => item.id), ['a', 'd', 'e']);

    // El primer ticket sigue vigente: una segunda solicitud no lo borra otra vez.
    await deletion.deleteById('b');
    expect(source.deleteRequests, ['b', 'c']);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();

    expect(source.items.map((item) => item.id), ['a', 'b', 'c', 'd', 'e']);
    expect(source.items.map((item) => item.id).toSet(), hasLength(5));
    expect(source.restores, hasLength(2));
  });

  testWidgets(
    'QA07: cambiar filtro durante el SnackBar no rompe la seleccion',
    (tester) async {
      await mount(tester);
      await _selectType(tester, 'Apartamento');
      await _swipe(tester, 'c');
      await tester.pumpAndSettle();

      await _selectType(tester, 'Pensionado');
      expect(_visibleIds(tester), ['b', 'd']);
      expect(find.text('Deshacer'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(source.items.map((item) => item.id), ['a', 'b', 'c', 'd', 'e']);
      expect(_visibleIds(tester), ['b', 'd']);
      expect(source.queries.last.type, AccommodationType.boardingHouse);

      await _selectType(tester, 'Apartamento');
      expect(_visibleIds(tester), ['a', 'c', 'e']);
      expect(source.items.where((item) => item.id == 'c'), hasLength(1));
    },
  );
}

class _CatalogQaHarness extends StatelessWidget {
  const _CatalogQaHarness({required this.deletion});

  final CatalogDeletionController<_DeletedSnapshot> deletion;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: CatalogUndoHost<_DeletedSnapshot>(
      controller: deletion,
      duration: const Duration(seconds: 5),
      child: Scaffold(
        body: ListView(
          children: [
            const CatalogFilterBar(),
            CatalogResultsSection(
              itemBuilder:
                  (context, item) => CatalogDismissible<_DeletedSnapshot>(
                    alojamiento: item,
                    controller: deletion,
                    child: SizedBox(
                      key: ValueKey('card-${item.id}'),
                      height: 65,
                      child: Text('Ficha ${item.id}'),
                    ),
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DeletedSnapshot {
  const _DeletedSnapshot(this.record, this.position);

  final Accommodation record;
  final int position;
}

class _ControlledCatalog implements CatalogReader {
  final _revisions = StreamController<int>.broadcast();
  final items = List<Accommodation>.of(_fixtures);
  final queries = <CatalogFilter>[];
  final deleteRequests = <String>[];
  final deletions = <_DeletedSnapshot>[];
  final restores = <_DeletedSnapshot>[];
  Completer<void>? deleteGate;
  bool failDelete = false;
  bool failRestore = false;
  int _revision = 0;

  @override
  Stream<int> get changes => _revisions.stream;

  @override
  Future<List<Accommodation>> query(CatalogFilter filter) async {
    queries.add(filter);
    return List.unmodifiable(
      items.where((item) {
        return item.available &&
            (filter.type == null || item.type == filter.type) &&
            (filter.departmentId == null ||
                item.departmentId == filter.departmentId) &&
            (filter.universityId == null ||
                item.universityIds.contains(filter.universityId));
      }),
    );
  }

  Future<_DeletedSnapshot> deleteById(String id) async {
    deleteRequests.add(id);
    if (deleteGate != null) await deleteGate!.future;
    if (failDelete) throw StateError('Fallo de escritura simulado');
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('ID inexistente: $id');
    // Guarda el orden global, no el indice de la lista filtrada.
    final stablePosition = _fixtures.indexWhere((item) => item.id == id);
    final snapshot = _DeletedSnapshot(items.removeAt(index), stablePosition);
    deletions.add(snapshot);
    _revisions.add(++_revision);
    return snapshot;
  }

  Future<void> restore(_DeletedSnapshot snapshot) async {
    restores.add(snapshot);
    if (failRestore) throw StateError('Fallo de restauracion simulado');
    if (items.any((item) => item.id == snapshot.record.id)) {
      throw StateError('Registro duplicado');
    }
    // Inserta segun la posicion estable: soporta dos borrados seguidos.
    final insertAt = items.indexWhere((item) {
      final stablePosition = _fixtures.indexWhere(
        (original) => original.id == item.id,
      );
      return stablePosition > snapshot.position;
    });
    if (insertAt == -1) {
      items.add(snapshot.record);
    } else {
      items.insert(insertAt, snapshot.record);
    }
    _revisions.add(++_revision);
  }

  Future<void> dispose() => _revisions.close();
}

Future<void> _selectType(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<AccommodationType?>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _swipe(WidgetTester tester, String id) async {
  final row = find.byWidgetPredicate(
    (widget) => widget is Dismissible && widget.key == ValueKey(id),
  );
  expect(row, findsOneWidget);
  await tester.drag(row, const Offset(-650, 0));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

List<String> _visibleIds(WidgetTester tester) {
  return tester
      .widgetList<SizedBox>(
        find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith('card-'),
        ),
      )
      .map((widget) => (widget.key! as ValueKey<String>).value.substring(5))
      .toList();
}

void _expectSameFields(Accommodation actual, Accommodation expected) {
  expect(actual.id, expected.id);
  expect(actual.title, expected.title);
  expect(actual.type, expected.type);
  expect(actual.location, expected.location);
  expect(actual.departmentId, expected.departmentId);
  expect(actual.universityIds, orderedEquals(expected.universityIds));
  expect(actual.monthlyPrice, expected.monthlyPrice);
  expect(actual.available, expected.available);
  expect(actual.bathrooms, expected.bathrooms);
  expect(actual.sizeSquareMeters, expected.sizeSquareMeters);
  expect(actual.imageUrls, orderedEquals(expected.imageUrls));
  expect(actual.contactName, expected.contactName);
  expect(actual.contactPhone, expected.contactPhone);
  expect(actual.contactEmail, expected.contactEmail);
}

const _fixtures = <Accommodation>[
  Accommodation(
    id: 'a',
    title: 'Ficha A',
    type: AccommodationType.apartment,
    location: 'Zona 3',
    departmentId: 'quetzaltenango',
    universityIds: ['umeso'],
    monthlyPrice: 1800,
    bathrooms: 1,
    sizeSquareMeters: 28,
    imageUrls: ['a-1.png'],
    contactName: 'Ana',
    contactPhone: '1001',
    contactEmail: 'a@example.test',
  ),
  Accommodation(
    id: 'b',
    title: 'Ficha B',
    type: AccommodationType.boardingHouse,
    location: 'Zona 1',
    departmentId: 'guatemala',
    universityIds: ['usac'],
    monthlyPrice: 1200,
    bathrooms: 2,
    sizeSquareMeters: 20,
    imageUrls: ['b-1.png'],
    contactName: 'Bruno',
    contactPhone: '1002',
    contactEmail: 'b@example.test',
  ),
  Accommodation(
    id: 'c',
    title: 'Ficha C',
    type: AccommodationType.apartment,
    location: 'Zona 9',
    departmentId: 'quetzaltenango',
    universityIds: ['umeso'],
    monthlyPrice: 2500,
    bathrooms: 2,
    sizeSquareMeters: 65,
    imageUrls: ['c-1.png', 'c-2.png'],
    contactName: 'Carlos',
    contactPhone: '1003',
    contactEmail: 'c@example.test',
  ),
  Accommodation(
    id: 'd',
    title: 'Ficha D',
    type: AccommodationType.boardingHouse,
    location: 'Zona 11',
    departmentId: 'guatemala',
    universityIds: ['usac'],
    monthlyPrice: 950,
    bathrooms: 1,
    sizeSquareMeters: 14,
    imageUrls: [],
    contactName: 'Dora',
    contactPhone: '1004',
    contactEmail: 'd@example.test',
  ),
  Accommodation(
    id: 'e',
    title: 'Ficha E',
    type: AccommodationType.apartment,
    location: 'Zona 2',
    departmentId: 'quetzaltenango',
    universityIds: ['umeso'],
    monthlyPrice: 2100,
    bathrooms: 1,
    sizeSquareMeters: 38,
    imageUrls: ['e-1.png'],
    contactName: 'Eva',
    contactPhone: '1005',
    contactEmail: 'e@example.test',
  ),
];
