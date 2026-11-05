import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easyhome/features/accommodations/data/owner_accommodation_repository.dart';
import 'package:easyhome/features/accommodations/data/owner_accommodation_store.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/entities/owner_accommodation_filter.dart';
import 'package:easyhome/features/accommodations/presentation/providers/my_accommodations_providers.dart';

void main() {
  group('OwnerAccommodationFilter', () {
    test('has immutable value equality and supports clearing the type', () {
      const first = OwnerAccommodationFilter(type: AccommodationType.apartment);
      const same = OwnerAccommodationFilter(type: AccommodationType.apartment);

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first.copyWith(clearType: true), const OwnerAccommodationFilter());
      expect(first.type, AccommodationType.apartment);
    });
  });

  group('myAccommodationsProvider', () {
    test(
      'queries initially and only queries again when the type changes',
      () async {
        final repository = _FakeOwnerAccommodationRepository();
        final container = ProviderContainer(
          overrides: [
            ownerAccommodationRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        await container.read(myAccommodationsProvider.future);
        expect(repository.requestedTypes, [null]);

        container
            .read(ownerAccommodationFilterProvider.notifier)
            .selectType(null);
        await Future<void>.delayed(Duration.zero);
        expect(repository.requestedTypes, [null]);

        container
            .read(ownerAccommodationFilterProvider.notifier)
            .selectType(AccommodationType.apartment);
        await container.read(myAccommodationsProvider.future);
        expect(repository.requestedTypes, [null, AccommodationType.apartment]);
      },
    );

    test('supports retry after a query failure', () async {
      final repository = _FakeOwnerAccommodationRepository()..failNext = true;
      final container = ProviderContainer(
        overrides: [
          ownerAccommodationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(myAccommodationsProvider.future),
        throwsA(isA<StateError>()),
      );
      container.invalidate(myAccommodationsProvider);
      await expectLater(
        container.read(myAccommodationsProvider.future),
        completion(isEmpty),
      );
      expect(repository.requestedTypes, [null, null]);
    });

    test(
      'a late response from an old filter cannot replace the current data',
      () async {
        final repository = _ControlledOwnerAccommodationRepository();
        final container = ProviderContainer(
          overrides: [
            ownerAccommodationRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        final initialRequest = container.read(myAccommodationsProvider.future);
        container
            .read(ownerAccommodationFilterProvider.notifier)
            .selectType(AccommodationType.apartment);
        final apartmentRequest = container.read(
          myAccommodationsProvider.future,
        );

        repository.requests[1].complete([_accommodation('apartment')]);
        await apartmentRequest;
        repository.requests[0].complete([_accommodation('old-all')]);
        await initialRequest;

        expect(
          container.read(myAccommodationsProvider).requireValue.single.id,
          'apartment',
        );
      },
    );
  });
}

class _FakeOwnerAccommodationRepository
    implements OwnerAccommodationRepository {
  final requestedTypes = <AccommodationType?>[];
  bool failNext = false;

  @override
  Future<List<OwnerAccommodation>> getOwnerAccommodations({
    AccommodationType? type,
  }) async {
    requestedTypes.add(type);
    if (failNext) {
      failNext = false;
      throw StateError('temporary read error');
    }
    return const [];
  }

  @override
  Future<void> deleteOwnerAccommodation(String id) async {}

  @override
  Future<void> restoreOwnerAccommodation(
    OwnerAccommodation accommodation,
  ) async {}
}

class _ControlledOwnerAccommodationRepository
    implements OwnerAccommodationRepository {
  final requests = <Completer<List<OwnerAccommodation>>>[];

  @override
  Future<List<OwnerAccommodation>> getOwnerAccommodations({
    AccommodationType? type,
  }) {
    final request = Completer<List<OwnerAccommodation>>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<void> deleteOwnerAccommodation(String id) async {}

  @override
  Future<void> restoreOwnerAccommodation(
    OwnerAccommodation accommodation,
  ) async {}
}

OwnerAccommodation _accommodation(String id) {
  return OwnerAccommodation(
    id: id,
    name: 'Test $id',
    type: 'Apartamento',
    address: 'Address $id',
    departmentId: 'department',
    universityIds: const ['university'],
    monthlyPrice: 1000,
    description: 'Description $id',
    bathrooms: 1,
    sizeSquareMeters: 30,
    contactName: 'Contact $id',
    contactPhone: '555-0100',
  );
}
