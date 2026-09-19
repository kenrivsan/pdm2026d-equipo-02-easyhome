import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../controllers/accommodation_search_controller.dart';

class AccommodationsPage extends StatelessWidget {
  const AccommodationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Easy Home')),
      body: Consumer<AccommodationSearchController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return EmptyState(
              title: 'No pudimos cargar los alojamientos',
              message: controller.errorMessage,
              icon: Icons.error_outline,
            );
          }

          final total = controller.filteredAccommodations.length;
          return EmptyState(
            title: '$total alojamientos disponibles',
            message:
                'Los filtros y el listado se implementarán en sus respectivos issues.',
          );
        },
      ),
    );
  }
}
