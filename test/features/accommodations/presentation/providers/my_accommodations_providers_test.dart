import 'dart:async';

import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_query.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_record.dart';
import 'package:easyhome/features/accommodations/domain/entities/owner_accommodation_filter.dart';
import 'package:easyhome/features/accommodations/presentation/providers/my_accommodations_providers.dart';
import 'package:easyhome/features/accommodations/presentation/providers/shared_accommodation_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_owner_shared_repository.dart';

void main() {
  test('filtro inmutable conserva igualdad y permite limpiar', () {
    const first = OwnerAccommodationFilter(type: AccommodationType.apartment);
    const same = OwnerAccommodationFilter(type: AccommodationType.apartment);
    expect(first, same);
    expect(first.hashCode, same.hashCode);
    expect(first.copyWith(clearType: true), const OwnerAccommodationFilter());
  });

  test('consulta solo publicaciones propias y cambia con el filtro', () async {
    final repository = FakeOwnerSharedRepository(
      records: [
        ownerRecord('apartment'),
        ownerRecord('boarding', type: AccommodationType.boardingHouse),
        ownerRecord('other', isOwned: false),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        sharedAccommodationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await repository.close();
    });
    final subscription = container.listen(myAccommodationsProvider, (_, __) {});
    addTearDown(subscription.close);

    expect(
      (await container.read(myAccommodationsProvider.future)).map((r) => r.id),
      ['apartment', 'boarding'],
    );
    expect(repository.requestedQueries, [
      const AccommodationQuery(onlyOwned: true),
    ]);
    container.read(ownerAccommodationFilterProvider.notifier).selectType(null);
    await Future<void>.delayed(Duration.zero);
    expect(repository.requestedQueries, hasLength(1));

    container
        .read(ownerAccommodationFilterProvider.notifier)
        .selectType(AccommodationType.apartment);
    expect(
      (await container.read(myAccommodationsProvider.future)).map((r) => r.id),
      ['apartment'],
    );
    expect(
      repository.requestedQueries.last,
      const AccommodationQuery(
        onlyOwned: true,
        type: AccommodationType.apartment,
      ),
    );
    container
        .read(ownerAccommodationFilterProvider.notifier)
        .selectType(AccommodationType.apartment);
    await Future<void>.delayed(Duration.zero);
    expect(repository.requestedQueries, hasLength(2));
  });

  test(
    'reintenta tras error y reconsulta al recibir revisión confirmada',
    () async {
      final repository = FakeOwnerSharedRepository()..failNextQuery = true;
      final container = ProviderContainer(
        overrides: [
          sharedAccommodationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await repository.close();
      });
      final subscription = container.listen(
        myAccommodationsProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);

      await expectLater(
        container.read(myAccommodationsProvider.future),
        throwsStateError,
      );
      expect(repository.requestedQueries, hasLength(1));
      await Future<void>.delayed(const Duration(milliseconds: 750));
      expect(container.read(myAccommodationsProvider).hasError, isTrue);
      expect(repository.requestedQueries, hasLength(1));
      container.invalidate(myAccommodationsProvider);
      expect(await container.read(myAccommodationsProvider.future), isEmpty);
      expect(repository.requestedQueries, hasLength(2));

      await repository.add(ownerRecord('new'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(
        (await container.read(myAccommodationsProvider.future)).single.id,
        'new',
      );
      expect(repository.requestedQueries, hasLength(3));
    },
  );

  test('respuesta tardía de filtro anterior no reemplaza la actual', () async {
    final repository = FakeOwnerSharedRepository();
    final requests = <Completer<List<AccommodationRecord>>>[];
    repository.onQuery = (_) {
      final request = Completer<List<AccommodationRecord>>();
      requests.add(request);
      return request.future;
    };
    final container = ProviderContainer(
      overrides: [
        sharedAccommodationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await repository.close();
    });
    final subscription = container.listen(myAccommodationsProvider, (_, __) {});
    addTearDown(subscription.close);

    final old = container.read(myAccommodationsProvider.future);
    container
        .read(ownerAccommodationFilterProvider.notifier)
        .selectType(AccommodationType.apartment);
    final current = container.read(myAccommodationsProvider.future);
    requests[1].complete([ownerRecord('apartment')]);
    await current;
    requests[0].complete([ownerRecord('old')]);
    await old;
    expect(
      container.read(myAccommodationsProvider).requireValue.single.id,
      'apartment',
    );
  });
}
