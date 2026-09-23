import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/accommodation_search_controller.dart';
import 'results_page.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AccommodationSearchController>();

    if (controller.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (controller.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Buscar alojamiento'),
        ),
        body: Center(
          child: Text(controller.errorMessage!),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar alojamiento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Departamento',
                border: OutlineInputBorder(),
              ),
              value: controller.selectedDepartmentId,
              items: controller.departments.map((department) {
                return DropdownMenuItem(
                  value: department.id,
                  child: Text(department.name),
                );
              }).toList(),
              onChanged: controller.selectDepartment,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Universidad',
                border: OutlineInputBorder(),
              ),
              value: controller.selectedUniversityId,
              items: controller.availableUniversities.map((university) {
                return DropdownMenuItem(
                  value: university.id,
                  child: Text(university.name),
                );
              }).toList(),
              onChanged: controller.selectedDepartmentId == null
                  ? null
                  : controller.selectUniversity,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.selectedDepartmentId != null &&
                      controller.selectedUniversityId != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResultsPage(),
                        ),
                      );
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