
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/owner_accommodation_store.dart';

class MyAccommodationsPage extends StatelessWidget {
  const MyAccommodationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis alojamientos'),
      ),
      body: ListenableBuilder(
        listenable: OwnerAccommodationStore.instance,
        builder: (context, child) {
          final items = OwnerAccommodationStore.instance.items;

          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no has publicado alojamientos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Tipo: ${item.type}'),
                      Text('Ubicación: ${item.address}'),
                      Text(
                        'Precio: L ${item.monthlyPrice.toStringAsFixed(2)} / mes',
                      ),
                      const SizedBox(height: 8),
                      Text(item.description),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
