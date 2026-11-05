import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation.dart';
import '../controllers/accommodation_search_controller.dart';
import '../controllers/catalog_providers.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = context.watch<AccommodationSearchController>();

    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (controller.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Buscar alojamiento')),
        body: Center(child: Text(controller.errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar alojamiento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey(
                'search-department-${controller.selectedDepartmentId}',
              ),
              decoration: const InputDecoration(
                labelText: 'Departamento',
                border: OutlineInputBorder(),
              ),
              initialValue: controller.selectedDepartmentId,
              items:
                  controller.departments.map((department) {
                    return DropdownMenuItem(
                      value: department.id,
                      child: Text(department.name),
                    );
                  }).toList(),
              onChanged: controller.selectDepartment,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(
                'search-university-${controller.selectedUniversityId}',
              ),
              decoration: const InputDecoration(
                labelText: 'Universidad',
                border: OutlineInputBorder(),
              ),
              initialValue: controller.selectedUniversityId,
              items:
                  controller.availableUniversities.map((university) {
                    return DropdownMenuItem(
                      value: university.id,
                      child: Text(university.name),
                    );
                  }).toList(),
              onChanged:
                  controller.selectedDepartmentId == null
                      ? null
                      : controller.selectUniversity,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  controller.selectedDepartmentId != null &&
                          controller.selectedUniversityId != null
                      ? () {
                        ref
                            .read(catalogFilterProvider.notifier)
                            .selectLocation(
                              departmentId: controller.selectedDepartmentId,
                              universityId: controller.selectedUniversityId,
                            );
                        ref
                            .read(appNavigationProvider.notifier)
                            .select(AppTab.accommodations);
                      }
                      : null,
              child: const Text('Ver resultados'),
            ),
          ],
        ),
      ),
    );
  }
}
