import 'dart:async';

import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_record.dart';
import 'package:easyhome/features/accommodations/presentation/pages/my_accommodations_page.dart';
import 'package:easyhome/features/accommodations/presentation/providers/shared_accommodation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_owner_shared_repository.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    FakeOwnerSharedRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedAccommodationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: MyAccommodationsPage()),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await repository.close();
    });
  }

  Future<void> selectPensionado(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownButtonFormField<AccommodationType?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pensionado').last);
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

  testWidgets('muestra cargando y luego solo publicaciones propias', (
    tester,
  ) async {
    final repository = FakeOwnerSharedRepository();
    final pending = Completer<List<AccommodationRecord>>();
    repository.onQuery = (_) => pending.future;
    await mount(tester, repository);
    expect(
      find.byKey(const ValueKey('my-accommodations-loading')),
      findsOneWidget,
    );
    pending.complete([ownerRecord('apartamento')]);
    await tester.pumpAndSettle();
    expect(find.text('Casa apartamento'), findsOneWidget);
    expect(find.text('Tipo: Apartamento'), findsOneWidget);
    expect(find.text('Ubicación: Dirección apartamento'), findsOneWidget);
    expect(find.text('Descripción apartamento'), findsOneWidget);
    expect(repository.requestedQueries.single.onlyOwned, isTrue);
    await tester.pump();
    expect(repository.requestedQueries, hasLength(1));
  });

  testWidgets('cambia el tipo y consulta el filtro seleccionado', (
    tester,
  ) async {
    final repository = FakeOwnerSharedRepository(
      records: [
        ownerRecord('apartamento'),
        ownerRecord('pensionado', type: AccommodationType.boardingHouse),
        ownerRecord('ajeno', isOwned: false),
      ],
    );
    await mount(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('Casa apartamento'), findsOneWidget);
    expect(find.text('Casa pensionado'), findsOneWidget);
    expect(find.text('Casa ajeno'), findsNothing);
    await selectPensionado(tester);
    expect(find.text('Casa pensionado'), findsOneWidget);
    expect(find.text('Casa apartamento'), findsNothing);
    expect(
      repository.requestedQueries.last.type,
      AccommodationType.boardingHouse,
    );
  });

  testWidgets('distingue vacío inicial y vacío por filtro', (tester) async {
    final repository = FakeOwnerSharedRepository();
    await mount(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('Todavía no has publicado alojamientos.'), findsOneWidget);
    expect(find.text('Agregar alojamiento'), findsOneWidget);

    await repository.add(ownerRecord('apartamento'));
    await tester.pumpAndSettle();
    expect(find.text('Casa apartamento'), findsOneWidget);
    await selectPensionado(tester);
    expect(
      find.text('No hay alojamientos que coincidan con este filtro.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Limpiar filtro'));
    await tester.pumpAndSettle();
    expect(find.text('Casa apartamento'), findsOneWidget);
    expect(
      tester
          .widget<DropdownButtonFormField<AccommodationType?>>(
            find.byType(DropdownButtonFormField<AccommodationType?>),
          )
          .initialValue,
      isNull,
    );
  });

  testWidgets('error permite reintentar la consulta', (tester) async {
    final repository = FakeOwnerSharedRepository()..failNextQuery = true;
    await mount(tester, repository);
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudieron cargar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(repository.requestedQueries, hasLength(2));
    expect(find.text('Todavía no has publicado alojamientos.'), findsOneWidget);
  });

  testWidgets(
    'borrado fallido conserva fila; Deshacer restaura snapshot y orden',
    (tester) async {
      final first = ownerRecord('primero');
      final second = ownerRecord('segundo');
      final third = ownerRecord('tercero');
      final repository = FakeOwnerSharedRepository(
        records: [first, second, third],
      );
      await mount(tester, repository);
      await tester.pumpAndSettle();
      repository.failNextDelete = true;
      await swipe(tester, second.id);
      await tester.pumpAndSettle();
      expect(find.text('Casa segundo'), findsOneWidget);
      expect(find.text('No se pudo borrar el alojamiento.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      await swipe(tester, second.id);
      await tester.pumpAndSettle();
      expect(repository.records.map((r) => r.id), ['primero', 'tercero']);
      expect(find.text('Casa segundo'), findsNothing);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(repository.restoredSnapshots.single.record, same(second));
      expect(repository.records, [first, second, third]);
    },
  );

  testWidgets('restauración fallida ofrece Reintentar sin duplicar', (
    tester,
  ) async {
    final record = ownerRecord('borrado');
    final repository = FakeOwnerSharedRepository(records: [record]);
    await mount(tester, repository);
    await tester.pumpAndSettle();
    await swipe(tester, record.id);
    await tester.pumpAndSettle();
    repository.failNextRestore = true;
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(repository.records, isEmpty);
    expect(find.text('Reintentar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(repository.records.single, same(record));
    expect(repository.restoredSnapshots, hasLength(2));
    expect(
      identical(
        repository.restoredSnapshots[0],
        repository.restoredSnapshots[1],
      ),
      isTrue,
    );
  });

  testWidgets('bloquea acción repetida y permite borrados consecutivos', (
    tester,
  ) async {
    final repository = FakeOwnerSharedRepository(
      records: [ownerRecord('uno'), ownerRecord('dos')],
    );
    await mount(tester, repository);
    await tester.pumpAndSettle();
    repository.deleteGate = Completer<void>();
    await swipe(tester, 'uno');
    await swipe(tester, 'uno');
    expect(repository.deleteCalls, 1);
    repository.deleteGate!.complete();
    await tester.pumpAndSettle();
    repository.deleteGate = null;
    await swipe(tester, 'dos');
    await tester.pumpAndSettle();
    expect(repository.records, isEmpty);
    expect(find.text('Deshacer'), findsOneWidget);
  });

  testWidgets('desmontar durante borrado pendiente no deja errores de UI', (
    tester,
  ) async {
    final repository = FakeOwnerSharedRepository(records: [ownerRecord('uno')]);
    await mount(tester, repository);
    await tester.pumpAndSettle();
    repository.deleteGate = Completer<void>();
    await swipe(tester, 'uno');
    await tester.pumpWidget(const SizedBox.shrink());
    repository.deleteGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
