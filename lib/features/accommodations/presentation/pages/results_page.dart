import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/accommodation.dart';
import '../controllers/accommodation_search_controller.dart';
import 'accommodation_detail_page.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AccommodationSearchController>();
    final accommodations = controller.filteredAccommodations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de búsqueda'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<AccommodationType?>(
              decoration: const InputDecoration(
                labelText: 'Tipo de alojamiento',
                border: OutlineInputBorder(),
              ),
              initialValue: controller.selectedType,
              items: const [
                DropdownMenuItem<AccommodationType?>(
                  value: null,
                  child: Text('Todos'),
                ),
                DropdownMenuItem<AccommodationType?>(
                  value: AccommodationType.apartment,
                  child: Text('Apartamento'),
                ),
                DropdownMenuItem<AccommodationType?>(
                  value: AccommodationType.boardingHouse,
                  child: Text('Pensionado'),
                ),
              ],
              onChanged: controller.selectType,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              decoration: const InputDecoration(
                labelText: 'Departamento',
                border: OutlineInputBorder(),
              ),
              initialValue: controller.selectedDepartmentId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todos'),
                ),
                ...controller.departments.map(
                  (department) => DropdownMenuItem<String?>(
                    value: department.id,
                    child: Text(department.name),
                  ),
                ),
              ],
              onChanged: controller.selectDepartment,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: accommodations.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron alojamientos disponibles para esta búsqueda.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: accommodations.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final accommodation = accommodations[index];

                        return Card(
                          child: ListTile(
                            onTap: () {
                               Navigator.push(
                                context,
                               MaterialPageRoute(
                                    builder: (context) => AccommodationDetailPage(
                                    accommodation: accommodation,
                                  ),
                                ),
                              );
                            },
                            title: Text(accommodation.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  accommodation.type ==
                                          AccommodationType.apartment
                                      ? 'Apartamento'
                                      : 'Pensionado',
                                ),
                                Text(accommodation.location),
                                Text(
                                  'Q${accommodation.monthlyPrice.toStringAsFixed(2)} al mes',
                                ),
                                Text(
                                  '${accommodation.bathrooms} baño(s) · '
                                  '${accommodation.sizeSquareMeters.toStringAsFixed(0)} m²',
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}