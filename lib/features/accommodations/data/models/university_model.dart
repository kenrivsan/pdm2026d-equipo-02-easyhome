import '../../domain/entities/university.dart';

class UniversityModel extends University {
  const UniversityModel({
    required super.id,
    required super.name,
    required super.departmentId,
  });

  factory UniversityModel.fromJson(Map<String, dynamic> json) {
    return UniversityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      departmentId: json['departmentId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'departmentId': departmentId,
      };
}