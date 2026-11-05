import 'package:easyhome/app/catalog_scope.dart';
import 'package:easyhome/features/accommodations/domain/entities/catalog_filter.dart';
import 'package:easyhome/features/accommodations/presentation/controllers/accommodation_search_controller.dart';
import 'package:flutter/widgets.dart';

/// Inyecta exactamente el repositorio del controlador y el filtro inicial del
/// escenario. Las selecciones posteriores pertenecen al Notifier de Riverpod.
class CatalogTestScope extends StatelessWidget {
  const CatalogTestScope({
    required this.controller,
    required this.child,
    super.key,
  });

  final AccommodationSearchController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => CatalogScope(
    repository: controller.accommodationRepository,
    initialFilter: CatalogFilter(
      type: controller.selectedType,
      departmentId: controller.selectedDepartmentId,
      universityId: controller.selectedUniversityId,
    ),
    child: child,
  );
}
