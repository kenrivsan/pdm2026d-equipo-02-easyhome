import 'accommodation.dart';

/// Complete canonical value for an accommodation publication.
///
/// The repository stores stable ordering metadata separately so that records
/// remain a pure representation of the publication itself.
final class AccommodationRecord {
  AccommodationRecord({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.departmentId,
    required List<String> universityIds,
    required this.monthlyPrice,
    required this.description,
    required this.available,
    required this.bathrooms,
    required this.sizeSquareMeters,
    required List<String> imageUrls,
    required this.contactName,
    required this.contactPhone,
    required this.contactEmail,
    this.isOwned = false,
  }) : universityIds = List.unmodifiable(universityIds),
       imageUrls = List.unmodifiable(imageUrls);

  final String id;
  final String title;
  final AccommodationType type;
  final String location;
  final String departmentId;
  final List<String> universityIds;
  final double monthlyPrice;
  final String description;
  final bool available;
  final int bathrooms;
  final double sizeSquareMeters;
  final List<String> imageUrls;
  final String contactName;
  final String contactPhone;
  final String? contactEmail;
  final bool isOwned;

  AccommodationRecord copyWith({bool? isOwned}) => AccommodationRecord(
    id: id,
    title: title,
    type: type,
    location: location,
    departmentId: departmentId,
    universityIds: universityIds,
    monthlyPrice: monthlyPrice,
    description: description,
    available: available,
    bathrooms: bathrooms,
    sizeSquareMeters: sizeSquareMeters,
    imageUrls: imageUrls,
    contactName: contactName,
    contactPhone: contactPhone,
    contactEmail: contactEmail,
    isOwned: isOwned ?? this.isOwned,
  );

  factory AccommodationRecord.fromAccommodation(
    Accommodation accommodation, {
    bool isOwned = false,
  }) {
    return AccommodationRecord(
      id: accommodation.id,
      title: accommodation.title,
      type: accommodation.type,
      location: accommodation.location,
      departmentId: accommodation.departmentId,
      universityIds: accommodation.universityIds,
      monthlyPrice: accommodation.monthlyPrice,
      description: accommodation.description,
      available: accommodation.available,
      bathrooms: accommodation.bathrooms,
      sizeSquareMeters: accommodation.sizeSquareMeters,
      imageUrls: accommodation.imageUrls,
      contactName: accommodation.contactName,
      contactPhone: accommodation.contactPhone,
      contactEmail: accommodation.contactEmail,
      isOwned: isOwned,
    );
  }

  Accommodation toAccommodation() => Accommodation(
    id: id,
    title: title,
    type: type,
    location: location,
    departmentId: departmentId,
    universityIds: universityIds,
    monthlyPrice: monthlyPrice,
    description: description,
    available: available,
    bathrooms: bathrooms,
    sizeSquareMeters: sizeSquareMeters,
    imageUrls: imageUrls,
    contactName: contactName,
    contactPhone: contactPhone,
    contactEmail: contactEmail,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccommodationRecord &&
          other.id == id &&
          other.title == title &&
          other.type == type &&
          other.location == location &&
          other.departmentId == departmentId &&
          _listEquals(other.universityIds, universityIds) &&
          other.monthlyPrice == monthlyPrice &&
          other.description == description &&
          other.available == available &&
          other.bathrooms == bathrooms &&
          other.sizeSquareMeters == sizeSquareMeters &&
          _listEquals(other.imageUrls, imageUrls) &&
          other.contactName == contactName &&
          other.contactPhone == contactPhone &&
          other.contactEmail == contactEmail &&
          other.isOwned == isOwned;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    type,
    location,
    departmentId,
    Object.hashAll(universityIds),
    monthlyPrice,
    description,
    available,
    bathrooms,
    sizeSquareMeters,
    Object.hashAll(imageUrls),
    contactName,
    contactPhone,
    contactEmail,
    isOwned,
  );
}

bool _listEquals(List<String> left, List<String> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
