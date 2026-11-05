import 'accommodation.dart';

/// Consulta inmutable del catálogo estudiantil. null representa «Todos».
class CatalogFilter {
  const CatalogFilter({this.type, this.departmentId, this.universityId});

  final AccommodationType? type;
  final String? departmentId;
  final String? universityId;

  bool get isEmpty =>
      type == null && departmentId == null && universityId == null;

  CatalogFilter withType(AccommodationType? value) => CatalogFilter(
    type: value,
    departmentId: departmentId,
    universityId: universityId,
  );

  CatalogFilter withLocation({String? departmentId, String? universityId}) =>
      CatalogFilter(
        type: type,
        departmentId: departmentId,
        universityId: universityId,
      );

  @override
  bool operator ==(Object other) =>
      other is CatalogFilter &&
      type == other.type &&
      departmentId == other.departmentId &&
      universityId == other.universityId;

  @override
  int get hashCode => Object.hash(type, departmentId, universityId);
}
