import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/accommodation_data_source.dart';
import '../../data/repositories/shared_accommodation_repository_impl.dart';
import '../../domain/entities/accommodation_query.dart';
import '../../domain/entities/accommodation_record.dart';
import '../../domain/repositories/shared_accommodation_repository.dart';

final sharedAccommodationRepositoryProvider =
    Provider<SharedAccommodationRepository>((ref) {
      final repository = SharedPreferencesAccommodationRepository(
        preferences: SharedPreferencesAsync(),
        loadInitialAccommodations: _loadInitialAccommodationRecords,
      );
      ref.onDispose(() => unawaited(repository.dispose()));
      return repository;
    });

/// Current write revision; values are emitted only after persisted mutations.
final sharedAccommodationRevisionProvider = StreamProvider<int>(
  (ref) => ref.watch(sharedAccommodationRepositoryProvider).changes,
);

/// Shared asynchronous query used by both owner and student catalog screens.
/// The active filter is part of the provider key, and committed revisions
/// automatically re-run the repository query.
final sharedAccommodationRecordsProvider =
    FutureProvider.family<List<AccommodationRecord>, AccommodationQuery>((
      ref,
      filter,
    ) {
      ref.listen(sharedAccommodationRevisionProvider, (_, next) {
        if (next.hasValue) ref.invalidateSelf();
      });
      return ref.watch(sharedAccommodationRepositoryProvider).query(filter);
    });

Future<List<AccommodationRecord>> _loadInitialAccommodationRecords() async {
  final initial = await InMemoryAccommodationDataSource().getAccommodations();
  return List.unmodifiable(initial.map(AccommodationRecord.fromAccommodation));
}
