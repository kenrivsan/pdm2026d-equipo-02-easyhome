import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_query.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation_record.dart';
import 'package:easyhome/features/accommodations/data/repositories/shared_accommodation_repository_impl.dart';
import 'package:easyhome/features/accommodations/presentation/providers/shared_accommodation_providers.dart';

void main() {
  test(
    'one provider repository feeds query results and publishes revisions',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repository = SharedPreferencesAccommodationRepository(
        preferences: SharedPreferencesAsync(),
        loadInitialAccommodations: () async => [_record('seed')],
        storageKey: 'provider-test.accommodations.v1',
      );
      final container = ProviderContainer(
        overrides: [
          sharedAccommodationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await repository.dispose();
      });

      expect(
        identical(
          container.read(sharedAccommodationRepositoryProvider),
          container.read(sharedAccommodationRepositoryProvider),
        ),
        isTrue,
      );

      final initial = await container.read(
        sharedAccommodationRecordsProvider(const AccommodationQuery()).future,
      );
      final initialIds = initial.map((record) => record.id).toList();
      final recordsUpdated = Completer<void>();
      var updatedIds = <String>[];
      final recordsSubscription = container.listen(
        sharedAccommodationRecordsProvider(const AccommodationQuery()),
        (_, value) {
          if (value.hasValue) {
            final ids = value.requireValue.map((record) => record.id).toList();
            if (ids.contains('new') && !recordsUpdated.isCompleted) {
              updatedIds = ids;
              recordsUpdated.complete();
            }
          }
        },
        fireImmediately: true,
      );
      addTearDown(recordsSubscription.close);
      expect(initialIds, ['seed']);

      final revisions = <int>[];
      final changed = Completer<void>();
      final subscription = container.listen(
        sharedAccommodationRevisionProvider,
        (_, value) {
          if (value.hasValue) {
            revisions.add(value.requireValue);
            if (value.requireValue == 1 && !changed.isCompleted) {
              changed.complete();
            }
          }
        },
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      // Allow Riverpod to attach the broadcast-stream subscription before the
      // first mutation; broadcast streams do not replay earlier revisions.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await repository.add(_record('new'));
      await changed.future;
      await recordsUpdated.future;
      expect(initialIds, ['seed']);
      expect(updatedIds, ['seed', 'new']);
      expect(revisions, [1]);
    },
  );
}

AccommodationRecord _record(String id) => AccommodationRecord(
  id: id,
  title: 'Accommodation $id',
  type: AccommodationType.apartment,
  location: 'Address $id',
  departmentId: 'guatemala',
  universityIds: const ['usac'],
  monthlyPrice: 1000,
  description: 'Description $id',
  available: true,
  bathrooms: 1,
  sizeSquareMeters: 30,
  imageUrls: const [],
  contactName: 'Contact $id',
  contactPhone: '555-0100',
  contactEmail: null,
);
