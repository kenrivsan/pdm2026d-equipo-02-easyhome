import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/accommodation.dart';
import '../providers/my_accommodations_providers.dart';
import 'add_accommodation_page.dart';

class MyAccommodationsPage extends ConsumerStatefulWidget {
  const MyAccommodationsPage({super.key});

  @override
  ConsumerState<MyAccommodationsPage> createState() =>
      _MyAccommodationsPageState();
}

class _MyAccommodationsPageState extends ConsumerState<MyAccommodationsPage> {
  @override
  void initState() {
    super.initState();
    ref.invalidate(myAccommodationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(ownerAccommodationFilterProvider);
    final accommodations = ref.watch(myAccommodationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis alojamientos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: DropdownButtonFormField<AccommodationType?>(
              key: const ValueKey('owner-accommodation-type-filter'),
              initialValue: filter.type,
              decoration: const InputDecoration(
                labelText: 'Tipo de alojamiento',
                prefixIcon: Icon(Icons.tune_rounded),
              ),
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
              onChanged:
                  ref
                      .read(ownerAccommodationFilterProvider.notifier)
                      .selectType,
            ),
          ),
          Expanded(
            child: accommodations.when(
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(
                      key: ValueKey('my-accommodations-loading'),
                    ),
                  ),
              error:
                  (error, stackTrace) => _ErrorState(
                    onRetry: () => ref.invalidate(myAccommodationsProvider),
                  ),
              data: (items) {
                if (items.isEmpty && filter.type != null) {
                  return _NoMatchesState(
                    onClear:
                        () =>
                            ref
                                .read(ownerAccommodationFilterProvider.notifier)
                                .clear(),
                  );
                }
                if (items.isEmpty) {
                  return _NoPublicationsState(onAdd: _openAddAccommodation);
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
          ),
        ],
      ),
    );
  }

  Future<void> _openAddAccommodation() async {
    final published = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddAccommodationPage()),
    );
    if (published == true && mounted) ref.invalidate(myAccommodationsProvider);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No se pudieron cargar tus alojamientos. Inténtalo de nuevo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

class _NoPublicationsState extends StatelessWidget {
  const _NoPublicationsState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Todavía no has publicado alojamientos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_home_work_outlined),
            label: const Text('Agregar alojamiento'),
          ),
        ],
      ),
    ),
  );
}

class _NoMatchesState extends StatelessWidget {
  const _NoMatchesState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No hay alojamientos que coincidan con este filtro.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Limpiar filtro'),
          ),
        ],
      ),
    ),
  );
}
