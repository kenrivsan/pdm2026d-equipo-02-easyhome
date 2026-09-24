import '../../domain/entities/accommodation.dart';
import '../models/accommodation_model.dart';

abstract interface class AccommodationDataSource {
  Future<List<AccommodationModel>> getAccommodations();
}

/// Fuente temporal para desarrollar el MVP sin depender aún de un backend.
class InMemoryAccommodationDataSource implements AccommodationDataSource {
  static const _accommodations = <AccommodationModel>[
    AccommodationModel(
      id: 'room-guatemala-1',
      title: 'Pensionado cerca de la USAC',
      type: AccommodationType.boardingHouse,
      location: 'Zona 12, Ciudad de Guatemala',
      departmentId: 'guatemala',
      universityIds: ['usac-central'],
      monthlyPrice: 1800,
      bathrooms: 1,
      sizeSquareMeters: 20,
      imageUrls: [
        'https://picsum.photos/seed/easyhome-usac/900/600',
      ],
      contactName: 'Persona anfitriona de ejemplo',
      contactPhone: '5555-0101',
    ),

    AccommodationModel(
      id: 'apartment-quetzaltenango-1',
      title: 'Apartamento para estudiantes',
      type: AccommodationType.apartment,
      location: 'Zona 3, Quetzaltenango',
      departmentId: 'quetzaltenango',
      universityIds: ['mesoamericana-quetzaltenango'],
      monthlyPrice: 2200,
      bathrooms: 1,
      sizeSquareMeters: 45,
      imageUrls: [
        'https://picsum.photos/seed/easyhome-quetzaltenango/900/600',
      ],
      contactName: 'Persona anfitriona de ejemplo',
      contactPhone: '5555-0102',
      contactEmail: 'host@example.com',
    ),

    AccommodationModel(
      id: 'apartment-guatemala-unavailable',
      title: 'Apartamento no disponible',
      type: AccommodationType.apartment,
      location: 'Zona 11, Ciudad de Guatemala',
      departmentId: 'guatemala',
      universityIds: ['usac-central'],
      monthlyPrice: 2500,
      bathrooms: 1,
      sizeSquareMeters: 40,
      imageUrls: [
        'https://picsum.photos/seed/easyhome-guatemala/900/600',
      ],
      contactName: 'Persona anfitriona de ejemplo',
      contactPhone: '5555-0103',
      available: false,
    ),
  ];

  @override
  Future<List<AccommodationModel>> getAccommodations() async {
    return List.unmodifiable(_accommodations);
  }
}