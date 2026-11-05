import 'dart:async';

import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_providers.dart';
import 'package:easyhome/features/accommodations/presentation/widgets/catalog_filter_bar.dart';
import 'package:easyhome/features/accommodations/presentation/widgets/catalog_results_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_catalog_reader.dart';

class _CatalogFixture extends StatelessWidget {
  const _CatalogFixture();

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          const CatalogFilterBar(),
          CatalogResultsSection(
            itemBuilder: (_, item) => Text(item.title, key: ValueKey(item.id)),
          ),
        ],
      ),
    ),
  );
}

Future<void> _mount(WidgetTester tester, FakeCatalogReader reader) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [catalogReaderProvider.overrideWithValue(reader)],
      child: const _CatalogFixture(),
    ),
  );
}

Future<void> _select(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<AccommodationType?>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  late FakeCatalogReader reader;
  setUp(() => reader = FakeCatalogReader());
  tearDown(() => reader.close());

  testWidgets('Todos, Apartamento y Pensionado consultan y cambian la lista', (
    tester,
  ) async {
    await _mount(tester, reader);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('apartment-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('boarding-1')), findsOneWidget);
    await _select(tester, 'Apartamento');
    expect(find.byKey(const ValueKey('apartment-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('boarding-1')), findsNothing);
    await _select(tester, 'Pensionado');
    expect(find.byKey(const ValueKey('boarding-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('apartment-1')), findsNothing);
    await _select(tester, 'Todos');
    expect(find.byKey(const ValueKey('apartment-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('boarding-1')), findsOneWidget);
    expect(reader.queries, hasLength(4));
  });

  testWidgets('vacío según filtro permite limpiar y recuperar Todos', (
    tester,
  ) async {
    reader.respond =
        (filter) async => filter.type == null ? FakeCatalogReader.fixtures : [];
    await _mount(tester, reader);
    await tester.pumpAndSettle();
    await _select(tester, 'Apartamento');
    expect(
      find.text(
        'No se encontraron alojamientos disponibles para esta búsqueda.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('apartment-1')), findsOneWidget);
    expect(find.text('Limpiar filtros'), findsNothing);
    expect(reader.queries, hasLength(3));
    // El control también muestra Todos después de limpiar desde otro widget.
    expect(find.text('Todos'), findsOneWidget);
  });

  testWidgets('muestra carga hasta que responde la consulta', (tester) async {
    final response = Completer<List<Accommodation>>();
    reader.respond = (_) => response.future;
    await _mount(tester, reader);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(FakeCatalogReader.fixtures);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const ValueKey('apartment-1')), findsOneWidget);
  });

  testWidgets('error espera Reintentar y luego recupera los datos', (
    tester,
  ) async {
    reader.respond = (_) async {
      if (reader.queries.length == 1) throw Exception('Error simulado');
      return FakeCatalogReader.fixtures;
    };
    await _mount(tester, reader);
    await tester.pumpAndSettle();
    expect(
      find.text('No fue posible cargar los alojamientos.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(reader.queries, hasLength(1));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('apartment-1')), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
    expect(reader.queries, hasLength(2));
  });

  testWidgets('rebuild y mismo filtro no generan consultas adicionales', (
    tester,
  ) async {
    await _mount(tester, reader);
    await tester.pumpAndSettle();
    await _select(tester, 'Apartamento');
    await _select(tester, 'Apartamento');
    await _mount(tester, reader);
    await tester.pumpAndSettle();
    expect(reader.queries, hasLength(2));
    expect(find.byKey(const ValueKey('apartment-1')), findsOneWidget);
  });
}
