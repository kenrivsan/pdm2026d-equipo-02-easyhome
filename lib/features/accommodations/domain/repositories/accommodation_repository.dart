import '../entities/accommodation.dart';

abstract interface class AccommodationRepository {
  Future<List<Accommodation>> getAccommodations();
}
