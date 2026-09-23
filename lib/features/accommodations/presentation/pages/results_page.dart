import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/accommodation.dart';
import '../controllers/accommodation_search_controller.dart';

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
      body: accommodations.isEmpty
          ? const Center(
              child: Text(
                'No se encontraron alojamientos disponibles para esta búsqueda.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: accommodations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final accommodation = accommodations[index];

                return Card(
                  child: ListTile(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Seleccionaste ${accommodation.title}',
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
                          accommodation.type == AccommodationType.apartment
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
    );
  }
}