import 'package:flutter_test/flutter_test.dart';

import 'package:easyhome/features/accommodations/data/models/accommodation_model.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';

void main() {
  test('serializa y reconstruye un alojamiento', () {
    const accommodation = AccommodationModel(
      id: 'room-1',
      title: 'Habitación universitaria',
      type: AccommodationType.boardingHouse,
      location: 'Zona 12',
      monthlyPrice: 1800,
    );

    final reconstructed = AccommodationModel.fromJson(accommodation.toJson());

    expect(reconstructed.id, accommodation.id);
    expect(reconstructed.type, AccommodationType.boardingHouse);
    expect(reconstructed.monthlyPrice, 1800);
  });
}
