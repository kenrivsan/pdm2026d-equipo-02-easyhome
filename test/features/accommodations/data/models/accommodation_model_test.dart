import 'package:flutter_test/flutter_test.dart';

import 'package:easyhome/features/accommodations/data/models/accommodation_model.dart';
import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';

void main() {
  test('serializa y reconstruye un alojamiento completo', () {
    const accommodation = AccommodationModel(
      id: 'accommodation-1',
      title: 'Apartamento universitario',
      type: AccommodationType.apartment,
      location: 'Zona 3, Quetzaltenango',
      departmentId: 'quetzaltenango',
      universityIds: ['mesoamericana'],
      monthlyPrice: 2200,
      bathrooms: 1,
      sizeSquareMeters: 45,
      imageUrls: [
        'https://example.com/apartamento-1.jpg',
        'https://example.com/apartamento-2.jpg',
      ],
      contactName: 'Maria Lopez',
      contactPhone: '5555-5555',
      contactEmail: 'maria@example.com',
      available: true,
    );

    final json = accommodation.toJson();
    final reconstructed = AccommodationModel.fromJson(json);

    expect(reconstructed.id, accommodation.id);
    expect(reconstructed.title, accommodation.title);
    expect(reconstructed.type, AccommodationType.apartment);
    expect(reconstructed.location, accommodation.location);
    expect(reconstructed.departmentId, 'quetzaltenango');
    expect(reconstructed.universityIds, ['mesoamericana']);
    expect(reconstructed.monthlyPrice, 2200);
    expect(reconstructed.available, true);
    expect(reconstructed.bathrooms, 1);
    expect(reconstructed.sizeSquareMeters, 45);
    expect(reconstructed.imageUrls.length, 2);
    expect(reconstructed.contactName, 'Maria Lopez');
    expect(reconstructed.contactPhone, '5555-5555');
    expect(reconstructed.contactEmail, 'maria@example.com');
  });
}
