import 'dart:async';

import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_deletion_controller.dart';
import 'package:easyhome/features/accommodations/presentation/widgets/catalog_dismissible.dart';
import 'package:easyhome/features/accommodations/presentation/widgets/catalog_undo_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _Repository repository;
  late CatalogDeletionController<_Snapshot> controller;

  setUp(() {
    repository = _Repository();
    controller = CatalogDeletionController(
      deleteById: repository.deleteById,
      restore: repository.restore,
    );
  });
  tearDown(() {
    controller.dispose();
    repository.dispose();
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CatalogUndoHost(
          controller: controller,
          duration: const Duration(seconds: 2),
          child: Scaffold(
            body: ListenableBuilder(
              listenable: repository,
              builder:
                  (context, _) => Column(
                    children: [
                      TextButton(
                        onPressed: repository.toggleFilter,
                        child: const Text('Cambiar filtro'),
                      ),
                      for (final alojamiento in repository.query())
                        CatalogDismissible(
                          alojamiento: alojamiento,
                          controller: controller,
                          child: SizedBox(
                            height: 55,
                            child: Center(child: Text(alojamiento.title)),
                          ),
                        ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> swipe(WidgetTester tester, String id) async {
    final row = find.byWidgetPredicate(
      (widget) => widget is Dismissible && widget.key == ValueKey(id),
    );
    await tester.drag(row, const Offset(-650, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  testWidgets('espera confirmacion; fallo conserva fila y permite reintentar', (
    tester,
  ) async {
    repository.deleteGate = Completer<void>();
    await mount(tester);
    await swipe(tester, '2');
    expect(repository.deleteCalls, ['2']);
    expect(find.text('Alojamiento 2'), findsOneWidget);
    expect(find.text('Deshacer'), findsNothing);
    await controller.deleteById('2');
    expect(repository.deleteCalls, ['2']);
    repository.deleteGate!.completeError(StateError('sin escritura'));
    await tester.pumpAndSettle();
    expect(find.text('Alojamiento 2'), findsOneWidget);
    expect(find.text('No se pudo borrar el alojamiento.'), findsOneWidget);
    expect(controller.isLocked('2'), isFalse);
    repository.deleteGate = null;
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await swipe(tester, '2');
    await tester.pumpAndSettle();
    expect(find.text('Alojamiento 2'), findsNothing);
    expect(repository.deleteCalls, ['2', '2']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Deshacer usa snapshot exacto, mismo ID, datos y orden 2 de 5', (
    tester,
  ) async {
    final original = repository.items.toList();
    await mount(tester);
    for (final row in tester.widgetList<Dismissible>(
      find.byType(Dismissible),
    )) {
      expect(row.key, isA<ValueKey<String>>());
    }
    await swipe(tester, '2');
    await tester.pumpAndSettle();
    expect(repository.items.map((a) => a.id), ['1', '3', '4', '5']);
    expect(find.text('Alojamiento 2'), findsNothing);
    expect(find.text('Deshacer'), findsOneWidget);
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(repository.receivedSnapshots.single, same(repository.snapshots[0]));
    expect(repository.items, orderedEquals(original));
    expect(repository.items[1], same(original[1]));
    expect(find.text('Alojamiento restaurado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'borrados consecutivos conservan Deshacer independiente y orden',
    (tester) async {
      await mount(tester);
      await swipe(tester, '2');
      await tester.pumpAndSettle();
      await swipe(tester, '3');
      await tester.pumpAndSettle();
      expect(repository.items.map((a) => a.id), ['1', '4', '5']);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(repository.items.map((a) => a.id), ['1', '2', '4', '5']);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(repository.items.map((a) => a.id), ['1', '2', '3', '4', '5']);
      expect(repository.receivedSnapshots, orderedEquals(repository.snapshots));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cambiar filtro durante SnackBar restaura sin forzar visibilidad',
    (tester) async {
      await mount(tester);
      await swipe(tester, '2');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar filtro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(repository.items.map((a) => a.id), ['1', '2', '3', '4', '5']);
      expect(find.text('Alojamiento 2'), findsNothing);
      await tester.tap(find.text('Cambiar filtro'));
      await tester.pumpAndSettle();
      expect(find.text('Alojamiento 2'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Dismissible && widget.key is ValueKey<String>,
        ),
        findsNWidgets(5),
      );
    },
  );

  testWidgets(
    'fallo al restaurar informa error y Reintentar conserva snapshot',
    (tester) async {
      await mount(tester);
      await swipe(tester, '2');
      await tester.pumpAndSettle();
      repository.failRestore = true;
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo restaurar el alojamiento.'), findsOneWidget);
      expect(find.text('Alojamiento restaurado.'), findsNothing);
      expect(find.text('Alojamiento 2'), findsNothing);
      expect(controller.isLocked('2'), isTrue);
      repository.failRestore = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Alojamiento 2'), findsOneWidget);
      expect(repository.receivedSnapshots, hasLength(2));
      expect(
        repository.receivedSnapshots[0],
        same(repository.receivedSnapshots[1]),
      );
      expect(controller.isLocked('2'), isFalse);
    },
  );

  testWidgets('expiracion libera operacion sin restaurar', (tester) async {
    await mount(tester);
    await swipe(tester, '2');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(controller.isLocked('2'), isFalse);
    expect(repository.receivedSnapshots, isEmpty);
    expect(repository.items, hasLength(4));
  });

  testWidgets('filtro desmonta fila mientras escritura sigue pendiente', (
    tester,
  ) async {
    repository.deleteGate = Completer<void>();
    await mount(tester);
    await swipe(tester, '2');
    await tester.tap(find.text('Cambiar filtro'));
    await tester.pumpAndSettle();
    repository.deleteGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Deshacer'), findsOneWidget);
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(repository.items, hasLength(5));
    expect(tester.takeException(), isNull);
  });

  test('restauracion lenta bloquea doble accion y ticket consumido', () async {
    final events = <CatalogDeletionEvent<_Snapshot>>[];
    final subscription = controller.events.listen(events.add);
    addTearDown(subscription.cancel);
    await controller.deleteById('2');
    await Future<void>.delayed(Duration.zero);
    final ticket = events.single.ticket!;
    repository.restoreGate = Completer<void>();
    final pending = controller.undo(ticket);
    await controller.undo(ticket);
    controller.expire(ticket);
    await controller.deleteById('2');
    expect(repository.receivedSnapshots, hasLength(1));
    expect(repository.deleteCalls, ['2']);
    repository.restoreGate!.complete();
    await pending;
    await controller.undo(ticket);
    expect(repository.items, hasLength(5));
    expect(repository.receivedSnapshots, hasLength(1));
  });

  test('tickets ajenos y vencidos no restauran', () async {
    final events = <CatalogDeletionEvent<_Snapshot>>[];
    final subscription = controller.events.listen(events.add);
    addTearDown(subscription.cancel);
    await controller.deleteById('2');
    await Future<void>.delayed(Duration.zero);
    final ticket = events.single.ticket!;
    final other = CatalogDeletionController<_Snapshot>(
      deleteById: repository.deleteById,
      restore: repository.restore,
    );
    await other.undo(ticket);
    other.dispose();
    controller.expire(ticket);
    await controller.undo(ticket);
    expect(repository.receivedSnapshots, isEmpty);
  });

  test(
    'confirmaciones fuera de orden mantienen cada snapshot por ID',
    () async {
      final first = Completer<_Snapshot>();
      final second = Completer<_Snapshot>();
      final restored = <_Snapshot>[];
      final concurrent = CatalogDeletionController<_Snapshot>(
        deleteById: (id) => id == '2' ? first.future : second.future,
        restore: (snapshot) async => restored.add(snapshot),
      );
      addTearDown(concurrent.dispose);
      final events = <CatalogDeletionEvent<_Snapshot>>[];
      final subscription = concurrent.events.listen(events.add);
      addTearDown(subscription.cancel);
      final pendingFirst = concurrent.deleteById('2');
      final pendingSecond = concurrent.deleteById('3');
      final snapshot2 = _Snapshot(repository.items[1], 2);
      final snapshot3 = _Snapshot(repository.items[2], 3);
      second.complete(snapshot3);
      await pendingSecond;
      first.complete(snapshot2);
      await pendingFirst;
      await Future<void>.delayed(Duration.zero);
      expect(events.map((event) => event.ticket!.id), ['3', '2']);
      await concurrent.undo(events[1].ticket!);
      await concurrent.undo(events[0].ticket!);
      expect(restored, [same(snapshot2), same(snapshot3)]);
    },
  );

  test('dispose durante escritura permite terminar sin notificar UI', () async {
    final gate = Completer<_Snapshot>();
    final disposable = CatalogDeletionController<_Snapshot>(
      deleteById: (_) => gate.future,
      restore: (_) async {},
    );
    final pending = disposable.deleteById('2');
    disposable.dispose();
    gate.complete(_Snapshot(repository.items[1], 2));
    await pending;
  });

  testWidgets('desmontar host durante borrado no usa contexto destruido', (
    tester,
  ) async {
    repository.deleteGate = Completer<void>();
    await mount(tester);
    await swipe(tester, '2');
    await tester.pumpWidget(const SizedBox.shrink());
    repository.deleteGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

/// Falso exclusivamente de pruebas, NO es persistencia ni API definitiva de #27.
class _Snapshot {
  _Snapshot(this.record, this.originalOrder);
  final Accommodation record;
  final int originalOrder;
}

class _Repository extends ChangeNotifier {
  final items = List.generate(5, (i) => _accommodation('${i + 1}'));
  final deleteCalls = <String>[];
  final snapshots = <_Snapshot>[];
  final receivedSnapshots = <_Snapshot>[];
  Completer<void>? deleteGate;
  Completer<void>? restoreGate;
  bool failRestore = false;
  bool filtered = false;

  List<Accommodation> query() =>
      items.where((item) => !filtered || item.id == '1').toList();

  void toggleFilter() {
    filtered = !filtered;
    notifyListeners();
  }

  Future<_Snapshot> deleteById(String id) async {
    deleteCalls.add(id);
    if (deleteGate != null) await deleteGate!.future;
    final record = items.singleWhere((item) => item.id == id);
    final snapshot = _Snapshot(record, int.parse(id));
    snapshots.add(snapshot);
    items.remove(record);
    notifyListeners(); // cambios confirmados, incluso antes del retorno.
    return snapshot;
  }

  Future<void> restore(_Snapshot snapshot) async {
    receivedSnapshots.add(snapshot);
    if (restoreGate != null) await restoreGate!.future;
    if (failRestore) throw StateError('sin escritura');
    if (items.any((item) => item.id == snapshot.record.id)) {
      throw StateError('duplicado');
    }
    items.add(snapshot.record);
    items.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
    notifyListeners();
  }
}

Accommodation _accommodation(String id) => Accommodation(
  id: id,
  title: 'Alojamiento $id',
  type: AccommodationType.apartment,
  location: 'Direccion $id',
  departmentId: 'departamento-$id',
  universityIds: ['universidad-$id', 'otra-universidad'],
  monthlyPrice: 1234.50,
  bathrooms: 2,
  sizeSquareMeters: 53.5,
  imageUrls: ['imagen-$id', 'otra-imagen'],
  contactName: 'Contacto $id',
  contactPhone: '5555-1234',
  contactEmail: 'contacto$id@example.com',
  available: false,
);
