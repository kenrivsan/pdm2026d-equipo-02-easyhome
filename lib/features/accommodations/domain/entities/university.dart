class University {
  const University({
    required this.id,
    required this.name,
    required this.departmentId,
  });

  final String id;
  final String name;

  /// Departamento geográfico donde se encuentra la universidad.
  final String departmentId;
}