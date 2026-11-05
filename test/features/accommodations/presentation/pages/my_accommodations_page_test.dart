import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easyhome/features/accommodations/data/owner_accommodation_repository.dart';
import 'package:easyhome/features/accommodations/data/owner_accommodation_store.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/presentation/pages/my_accommodations_page.dart';
import 'package:easyhome/features/accommodations/presentation/providers/my_accommodations_providers.dart';

void main() {
  testWidgets('muestra cargando y luego las publicaciones', (tester) async {
    final pending = Completer<List<OwnerAccommodation>>();
    final repository = _FakeOwnerAccommodationRepository(
      onGet: (_) => pending.future,
    );

    await tester.pumpWidget(_page(repository));
    expect(
      find.byKey(const ValueKey('my-accommodations-loading')),
      findsOneWidget,
    );

    pending.complete([_accommodation('apartamento', 'Apartamento')]);
    await tester.pumpAndSettle();

    expect(find.text('Casa apartamento'), findsOneWidget);
    expect(find.text('Tipo: Apartamento'), findsOneWidget);
    expect(find.text('Ubicación: Dirección apartamento'), findsOneWidget);
    expect(find.text('Descripción apartamento'), findsOneWidget);
  });

  testWidgets('cambia el tipo y consulta el filtro seleccionado', (
    tester,
  ) async {
    final repository = _FakeOwnerAccommodationRepository(
      onGet:
          (type) async => switch (type) {
            AccommodationType.apartment => [
              _accommodation('apartamento', 'Apartamento'),
            ],
            AccommodationType.boardingHouse => [
              _accommodation('pensionado', 'Pensionado'),
            ],
            null => [
              _accommodation('apartamento', 'Apartamento'),
              _accommodation('pensionado', 'Pensionado'),
            ],
          },
    );

    await tester.pumpWidget(_page(repository));
    await tester.pumpAndSettle();
    expect(find.text('Casa apartamento'), findsOneWidget);
    expect(find.text('Casa pensionado'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('owner-accommodation-type-filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pensionado').last);
    await tester.pumpAndSettle();

    expect(repository.requestedTypes, [null, AccommodationType.boardingHouse]);
    expect(find.text('Casa pensionado'), findsOneWidget);
    expect(find.text('Casa apartamento'), findsNothing);
  });

  testWidgets('distingue el listado sin publicaciones y ofrece agregar', (
    tester,
  ) async {
    final repository = _FakeOwnerAccommodationRepository(
      onGet: (_) async => const [],
    );

    await tester.pumpWidget(_page(repository));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no has publicado alojamientos.'), findsOneWidget);
    expect(find.text('Agregar alojamiento'), findsOneWidget);
  });

  testWidgets('vacío por filtro permite limpiar y volver a ver el listado', (
    tester,
  ) async {
    final repository = _FakeOwnerAccommodationRepository(
      onGet:
          (type) async =>
              type == AccommodationType.boardingHouse
                  ? const []
                  : [_accommodation('apartamento', 'Apartamento')],
    );

    await tester.pumpWidget(_page(repository));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('owner-accommodation-type-filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pensionado').last);
    await tester.pumpAndSettle();

    expect(
      find.text('No hay alojamientos que coincidan con este filtro.'),
      findsOneWidget,
    );
    expect(find.text('Limpiar filtro'), findsOneWidget);
    expect(find.text('Todavía no has publicado alojamientos.'), findsNothing);

    await tester.tap(find.text('Limpiar filtro'));
    await tester.pumpAndSettle();
    expect(find.text('Casa apartamento'), findsOneWidget);
  });

  testWidgets('error permite reintentar la consulta', (tester) async {
    var requests = 0;
    final repository = _FakeOwnerAccommodationRepository(
      onGet: (_) async {
        requests++;
        if (requests == 1) throw StateError('temporary error');
        return const [];
      },
    );

    await tester.pumpWidget(_page(repository));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudieron cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('Todavía no has publicado alojamientos.'), findsOneWidget);
  });
}

Widget _page(_FakeOwnerAccommodationRepository repository) {
  return ProviderScope(
    overrides: [
      ownerAccommodationRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: MyAccommodationsPage()),
  );
}

class _FakeOwnerAccommodationRepository
    implements OwnerAccommodationRepository {
  _FakeOwnerAccommodationRepository({required this.onGet});

  final Future<List<OwnerAccommodation>> Function(AccommodationType?) onGet;
  final requestedTypes = <AccommodationType?>[];

  @override
  Future<List<OwnerAccommodation>> getOwnerAccommodations({
    AccommodationType? type,
  }) {
    requestedTypes.add(type);
    return onGet(type);
  }

  @override
  Future<void> deleteOwnerAccommodation(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> restoreOwnerAccommodation(
    OwnerAccommodation accommodation,
  ) async {
    throw UnimplementedError();
  }
}

OwnerAccommodation _accommodation(String id, String type) {
  return OwnerAccommodation(
    id: id,
    name: 'Casa $id',
    type: type,
    address: 'Dirección $id',
    departmentId: 'department',
    universityIds: const ['university'],
    monthlyPrice: 1200,
    description: 'Descripción $id',
    bathrooms: 1,
    sizeSquareMeters: 35,
    contactName: 'Contacto $id',
    contactPhone: '555-0100',
  );
}
