enum AccommodationType {
  apartment,
  boardingHouse,
}

class Accommodation {
  const Accommodation({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.departmentId,
    required this.universityIds,
    required this.monthlyPrice,
    required this.bathrooms,
    required this.sizeSquareMeters,
    required this.imageUrls,
    required this.contactName,
    required this.contactPhone,
    this.contactEmail,
    this.available = true,
  });

  final String id;
  final String title;
  final AccommodationType type;

  /// Dirección o descripción de la ubicación del alojamiento.
  final String location;

  /// Departamento geográfico al que pertenece el alojamiento.
  final String departmentId;

  /// Universidades cercanas o relacionadas con el alojamiento.
  final List<String> universityIds;

  final double monthlyPrice;
  final bool available;

  /// Cantidad de baños disponibles.
  final int bathrooms;

  /// Tamaño aproximado del alojamiento en metros cuadrados.
  final double sizeSquareMeters;

  /// Imágenes que podrán utilizarse en listado y detalle.
  final List<String> imageUrls;

  /// Información de contacto del encargado.
  final String contactName;
  final String contactPhone;
  final String? contactEmail;
}