import '../../domain/entities/accommodation.dart';

class AccommodationModel extends Accommodation {
  const AccommodationModel({
    required super.id,
    required super.title,
    required super.type,
    required super.location,
    required super.departmentId,
    required super.universityIds,
    required super.monthlyPrice,
    required super.bathrooms,
    required super.sizeSquareMeters,
    required super.imageUrls,
    required super.contactName,
    required super.contactPhone,
    super.contactEmail,
    super.available,
  });

  factory AccommodationModel.fromJson(Map<String, dynamic> json) {
    return AccommodationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: AccommodationType.values.byName(json['type'] as String),
      location: json['location'] as String,
      departmentId: json['departmentId'] as String,
      universityIds: List<String>.from(json['universityIds'] as List),
      monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
      bathrooms: json['bathrooms'] as int,
      sizeSquareMeters: (json['sizeSquareMeters'] as num).toDouble(),
      imageUrls: List<String>.from(json['imageUrls'] as List),
      contactName: json['contactName'] as String,
      contactPhone: json['contactPhone'] as String,
      contactEmail: json['contactEmail'] as String?,
      available: json['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'location': location,
    'departmentId': departmentId,
    'universityIds': universityIds,
    'monthlyPrice': monthlyPrice,
    'available': available,
    'bathrooms': bathrooms,
    'sizeSquareMeters': sizeSquareMeters,
    'imageUrls': imageUrls,
    'contactName': contactName,
    'contactPhone': contactPhone,
    'contactEmail': contactEmail,
  };
}
