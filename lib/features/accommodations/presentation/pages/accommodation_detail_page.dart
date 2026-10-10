import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/accommodation.dart';

class AccommodationDetailPage extends StatelessWidget {
  const AccommodationDetailPage({super.key, required this.accommodation});

  final Accommodation accommodation;

  @override
  Widget build(BuildContext context) {
    final typeLabel =
        accommodation.type == AccommodationType.apartment
            ? 'Apartamento'
            : 'Pensionado';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del alojamiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGEN PRINCIPAL
                if (accommodation.imageUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 320,
                      child: Image.network(
                        accommodation.imageUrls.first,
                        fit: BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return Container(
                            color: AppTheme.lightBlue,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.lightBlue,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    size: 52,
                                    color: AppTheme.navy,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No se pudo cargar la imagen',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  _buildNoImagesMessage(),

                const SizedBox(height: 22),

                // INFORMACIÓN PRINCIPAL
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 22,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              accommodation.title,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  accommodation.available
                                      ? const Color(0xFFE8F7F0)
                                      : const Color(0xFFFFEEEE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  accommodation.available
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  size: 16,
                                  color:
                                      accommodation.available
                                          ? AppTheme.success
                                          : Colors.redAccent,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  accommodation.available
                                      ? 'Disponible'
                                      : 'No disponible',
                                  style: TextStyle(
                                    color:
                                        accommodation.available
                                            ? AppTheme.success
                                            : Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              accommodation.location,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _FeatureChip(
                            icon: Icons.apartment_rounded,
                            text: typeLabel,
                          ),
                          _FeatureChip(
                            icon: Icons.bathroom_outlined,
                            text: '${accommodation.bathrooms} baño(s)',
                          ),
                          _FeatureChip(
                            icon: Icons.square_foot,
                            text:
                                '${accommodation.sizeSquareMeters.toStringAsFixed(0)} m²',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const Divider(),

                      const SizedBox(height: 18),

                      const Text(
                        'Precio mensual',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Q${accommodation.monthlyPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // GALERÍA
                if (accommodation.imageUrls.length > 1) ...[
                  const Text(
                    'Imágenes',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: accommodation.imageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 220,
                            height: 150,
                            child: Image.network(
                              accommodation.imageUrls[index],
                              fit: BoxFit.cover,
                              webHtmlElementStrategy:
                                  WebHtmlElementStrategy.prefer,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.lightBlue,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: AppTheme.navy,
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
                  const SizedBox(height: 24),
                ],

                // CONTACTO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.contact_phone_outlined,
                            color: AppTheme.navy,
                            size: 26,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Información de contacto',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      _ContactRow(
                        icon: Icons.person_outline,
                        label: 'Encargado',
                        value: accommodation.contactName,
                      ),

                      const SizedBox(height: 16),

                      _ContactRow(
                        icon: Icons.phone_outlined,
                        label: 'Teléfono',
                        value: accommodation.contactPhone,
                      ),

                      if (accommodation.contactEmail != null &&
                          accommodation.contactEmail!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _ContactRow(
                          icon: Icons.email_outlined,
                          label: 'Correo',
                          value: accommodation.contactEmail!,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoImagesMessage() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 52,
            color: AppTheme.navy,
          ),
          SizedBox(height: 10),
          Text(
            'No hay imágenes disponibles.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.navy, size: 17),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
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
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppTheme.navy, size: 21),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
