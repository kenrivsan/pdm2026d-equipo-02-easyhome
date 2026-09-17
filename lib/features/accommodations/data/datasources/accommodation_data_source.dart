import '../models/accommodation_model.dart';

abstract interface class AccommodationDataSource {
  Future<List<AccommodationModel>> getAccommodations();
}

/// Fuente temporal para desarrollar el MVP sin depender aún de un backend.
class InMemoryAccommodationDataSource implements AccommodationDataSource {
  @override
  Future<List<AccommodationModel>> getAccommodations() async => const [];
}
