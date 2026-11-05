import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/accommodation.dart';
import '../controllers/catalog_providers.dart';

/// Control de tipo reutilizable para conectar ResultsPage al contrato compartido.
class CatalogFilterBar extends ConsumerWidget {
  const CatalogFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(catalogFilterProvider);
    return DropdownButtonFormField<AccommodationType?>(
      key: ValueKey(filter.type),
      initialValue: filter.type,
      decoration: const InputDecoration(labelText: 'Tipo de alojamiento'),
      items: const [
        DropdownMenuItem(value: null, child: Text('Todos')),
        DropdownMenuItem(
          value: AccommodationType.apartment,
          child: Text('Apartamento'),
        ),
        DropdownMenuItem(
          value: AccommodationType.boardingHouse,
          child: Text('Pensionado'),
        ),
      ],
      onChanged: ref.read(catalogFilterProvider.notifier).selectType,
    );
  }
}
