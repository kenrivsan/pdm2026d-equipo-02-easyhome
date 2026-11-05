import 'dart:async';

import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/entities/catalog_filter.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/catalog_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_catalog_reader.dart';

void main() {
  late FakeCatalogReader reader;
  late ProviderContainer container;

  setUp(() {
    reader = FakeCatalogReader();
    container = ProviderContainer(
      overrides: [catalogReaderProvider.overrideWithValue(reader)],
    );
  });

  tearDown(() async {
    container.dispose();
    await reader.close();
  });

  test('filtros equivalentes tienen igualdad y hash por valor', () {
    const first = CatalogFilter(
      type: AccommodationType.apartment,
      departmentId: 'quetzaltenango',
      universityId: 'meso',
    );
    const equal = CatalogFilter(
      type: AccommodationType.apartment,
      departmentId: 'quetzaltenango',
      universityId: 'meso',
    );
    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(first.withType(null), isNot(first));
    expect(first.type, AccommodationType.apartment);
    expect(first.withType(null).departmentId, first.departmentId);
    expect(first.withType(null).universityId, first.universityId);
  });

  test(
    'consulta al cambiar tipo y conserva departamento y universidad',
    () async {
      final notifier = container.read(catalogFilterProvider.notifier);
      notifier.selectLocation(
        departmentId: 'quetzaltenango',
        universityId: 'meso',
      );
      expect(await container.read(catalogResultsProvider.future), hasLength(1));
      notifier.selectType(AccommodationType.boardingHouse);
      expect(await container.read(catalogResultsProvider.future), isEmpty);
      expect(reader.queries, hasLength(2));
      expect(reader.queries.last.departmentId, 'quetzaltenango');
      expect(reader.queries.last.universityId, 'meso');
    },
  );

  test(
    'repetir filtro equivalente o leer de nuevo no repite consulta',
    () async {
      final notifier = container.read(catalogFilterProvider.notifier);
      notifier.selectType(AccommodationType.apartment);
      await container.read(catalogResultsProvider.future);
      notifier.setFilter(
        const CatalogFilter(type: AccommodationType.apartment),
      );
      await container.pump();
      await container.read(catalogResultsProvider.future);
      expect(reader.queries, hasLength(1));
    },
  );

  test(
    'seleccionar departamento sin universidad limpia la selección previa',
    () {
      final notifier = container.read(catalogFilterProvider.notifier);
      notifier.selectLocation(
        departmentId: 'quetzaltenango',
        universityId: 'meso',
      );
      notifier.selectLocation(departmentId: 'guatemala');
      expect(container.read(catalogFilterProvider).universityId, isNull);
      expect(container.read(catalogFilterProvider).departmentId, 'guatemala');
    },
  );

  test('limpiar filtros vuelve a consultar Todos', () async {
    final notifier = container.read(catalogFilterProvider.notifier);
    notifier.selectType(AccommodationType.apartment);
    expect(await container.read(catalogResultsProvider.future), hasLength(1));
    notifier.clear();
    expect(await container.read(catalogResultsProvider.future), hasLength(2));
    expect(reader.queries.last, const CatalogFilter());
    expect(reader.queries, hasLength(2));
  });

  test(
    'notificación del origen invalida consulta manteniendo el filtro',
    () async {
      container
          .read(catalogFilterProvider.notifier)
          .selectType(AccommodationType.apartment);
      await container.read(catalogResultsProvider.future);
      reader.changesController.add(1);
      await container.pump();
      await container.read(catalogResultsProvider.future);
      expect(reader.queries, hasLength(2));
      expect(reader.queries.last.type, AccommodationType.apartment);
      expect(reader.changesController.hasListener, isTrue);
      container.dispose();
      expect(reader.changesController.hasListener, isFalse);
      // Evita un segundo dispose en tearDown.
      container = ProviderContainer();
    },
  );

  test('respuesta antigua no reemplaza resultados del nuevo filtro', () async {
    final oldResponse = Completer<List<Accommodation>>();
    final newResponse = Completer<List<Accommodation>>();
    reader.respond =
        (filter) =>
            filter.type == null ? oldResponse.future : newResponse.future;
    final subscription = container.listen(catalogResultsProvider, (_, _) {});
    addTearDown(subscription.close);
    expect(container.read(catalogResultsProvider).isLoading, isTrue);
    container
        .read(catalogFilterProvider.notifier)
        .selectType(AccommodationType.apartment);
    await container.pump();
    newResponse.complete([FakeCatalogReader.fixtures.first]);
    expect(await container.read(catalogResultsProvider.future), [
      FakeCatalogReader.fixtures.first,
    ]);
    oldResponse.complete([FakeCatalogReader.fixtures.last]);
    await container.pump();
    expect(
      container.read(catalogResultsProvider).requireValue.single.id,
      'apartment-1',
    );
    expect(reader.queries, hasLength(2));
  });

  test('resultados expuestos no permiten modificar la lista', () async {
    final results = await container.read(catalogResultsProvider.future);
    expect(() => results.clear(), throwsUnsupportedError);
  });

  test('repetir la misma revisión no dispara una consulta adicional', () async {
    await container.read(catalogResultsProvider.future);
    reader.changesController.add(1);
    await container.pump();
    await container.read(catalogResultsProvider.future);
    reader.changesController.add(1);
    await container.pump();
    await container.read(catalogResultsProvider.future);
    expect(reader.queries, hasLength(2));
  });
}
