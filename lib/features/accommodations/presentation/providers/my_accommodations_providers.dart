import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/owner_accommodation_repository.dart';
import '../../data/owner_accommodation_store_read_adapter.dart';
import '../../data/owner_accommodation_store.dart';
import '../../domain/entities/accommodation.dart';
import '../../domain/entities/owner_accommodation_filter.dart';

final ownerAccommodationRepositoryProvider =
    Provider<OwnerAccommodationRepository>(
      (ref) =>
          OwnerAccommodationStoreReadAdapter(OwnerAccommodationStore.instance),
    );

final ownerAccommodationFilterProvider = NotifierProvider<
  OwnerAccommodationFilterNotifier,
  OwnerAccommodationFilter
>(OwnerAccommodationFilterNotifier.new);

class OwnerAccommodationFilterNotifier
    extends Notifier<OwnerAccommodationFilter> {
  @override
  OwnerAccommodationFilter build() => const OwnerAccommodationFilter();

  void selectType(AccommodationType? type) {
    state = OwnerAccommodationFilter(type: type);
  }

  void clear() {
    state = const OwnerAccommodationFilter();
  }
}

final myAccommodationsProvider = FutureProvider<List<OwnerAccommodation>>((
  ref,
) {
  final filter = ref.watch(ownerAccommodationFilterProvider);
  final repository = ref.watch(ownerAccommodationRepositoryProvider);
  return repository.getOwnerAccommodations(type: filter.type);
});
