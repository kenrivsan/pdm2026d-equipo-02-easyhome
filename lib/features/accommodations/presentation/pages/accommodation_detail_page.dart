import 'package:flutter/material.dart';

import '../../domain/entities/accommodation.dart';

class AccommodationDetailPage extends StatelessWidget {
  const AccommodationDetailPage({
    super.key,
    required this.accommodation,
  });

  final Accommodation accommodation;

  @override
  Widget build(BuildContext context) {
    final typeLabel = accommodation.type == AccommodationType.apartment
        ? 'Apartamento'
        : 'Pensionado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del alojamiento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              accommodation.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              typeLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),

            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Ubicación',
              value: accommodation.location,
            ),
            const SizedBox(height: 12),

            _DetailRow(
              icon: accommodation.available
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              label: 'Disponibilidad',
              value: accommodation.available
                  ? 'Disponible'
                  : 'No disponible',
            ),
            const SizedBox(height: 12),

            _DetailRow(
              icon: Icons.bathroom_outlined,
              label: 'Baños',
              value: '${accommodation.bathrooms}',
            ),
            const SizedBox(height: 12),

            _DetailRow(
              icon: Icons.square_foot,
              label: 'Tamaño',
              value:
                  '${accommodation.sizeSquareMeters.toStringAsFixed(0)} m²',
            ),
            const SizedBox(height: 12),

            _DetailRow(
              icon: Icons.payments_outlined,
              label: 'Precio mensual',
              value:
                  'Q${accommodation.monthlyPrice.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 28),

            Text(
              'Imágenes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            if (accommodation.imageUrls.isEmpty)
              const Text('No hay imágenes disponibles.')
            else
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: accommodation.imageUrls.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final imageUrl = accommodation.imageUrls[index];

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 260,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 48,
                                    ),
                                    SizedBox(height: 8),
                                    Text('Imagen disponible'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 28),

            Text(
              'Información de contacto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            _DetailRow(
              icon: Icons.person_outline,
              label: 'Encargado',
              value: accommodation.contactName,
            ),
            const SizedBox(height: 12),

            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Teléfono',
              value: accommodation.contactPhone,
            ),

            if (accommodation.contactEmail != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.email_outlined,
                label: 'Correo',
                value: accommodation.contactEmail!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}