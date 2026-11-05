import 'accommodation.dart';
import 'accommodation_record.dart';

/// Immutable query shared by owner and student catalog lists.
final class AccommodationQuery {
  const AccommodationQuery({
    this.type,
    this.departmentId,
    this.universityId,
    this.onlyOwned = false,
  });

  final AccommodationType? type;
  final String? departmentId;
  final String? universityId;
  final bool onlyOwned;

  bool matches(AccommodationRecord record) {
    return (type == null || record.type == type) &&
        (departmentId == null || record.departmentId == departmentId) &&
        (universityId == null || record.universityIds.contains(universityId)) &&
        (!onlyOwned || record.isOwned);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccommodationQuery &&
          other.type == type &&
          other.departmentId == departmentId &&
          other.universityId == universityId &&
          other.onlyOwned == onlyOwned;

  @override
  int get hashCode => Object.hash(type, departmentId, universityId, onlyOwned);
}
