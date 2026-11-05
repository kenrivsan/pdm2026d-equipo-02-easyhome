import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/shared_owner_accommodation_reader.dart';
import '../../domain/entities/accommodation.dart';
import '../../domain/entities/accommodation_record.dart';
import '../../domain/entities/owner_accommodation_filter.dart';
import 'shared_accommodation_providers.dart';

final ownerAccommodationFilterProvider = NotifierProvider<
  OwnerAccommodationFilterNotifier,
  OwnerAccommodationFilter
>(OwnerAccommodationFilterNotifier.new);

class OwnerAccommodationFilterNotifier
    extends Notifier<OwnerAccommodationFilter> {
  @override
  OwnerAccommodationFilter build() => const OwnerAccommodationFilter();

  void selectType(AccommodationType? type) {
    if (state.type == type) return;
    state = OwnerAccommodationFilter(type: type);
  }

  void clear() {
    state = const OwnerAccommodationFilter();
  }
}

final myAccommodationsProvider = FutureProvider<List<AccommodationRecord>>(
  (ref) {
    final filter = ref.watch(ownerAccommodationFilterProvider);
    ref.watch(sharedAccommodationRevisionProvider);
    final repository = ref.watch(sharedAccommodationRepositoryProvider);
    return SharedOwnerAccommodationReader(repository).query(filter);
  },
  // El error permanece visible hasta que Reintentar invalida este provider.
  retry: (_, _) => null,
);
