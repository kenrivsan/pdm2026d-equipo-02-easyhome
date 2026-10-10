import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_theme.dart';
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
      appBar: AppBar(title: const Text('Resultados de búsqueda')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ENCABEZADO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.navy, AppTheme.navyDark],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Alojamientos disponibles',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        accommodations.length == 1
                            ? 'Encontramos 1 opción para ti.'
                            : 'Encontramos ${accommodations.length} opciones para ti.',
                        style: const TextStyle(
                          color: Color(0xFFDDEAF6),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // FILTROS
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10000000),
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
                          Icon(Icons.tune_rounded, color: AppTheme.navy),
                          SizedBox(width: 10),
                          Text(
                            'Filtrar resultados',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      DropdownButtonFormField<AccommodationType?>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo de alojamiento',
                          prefixIcon: Icon(Icons.home_work_outlined),
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
                          prefixIcon: Icon(Icons.location_on_outlined),
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
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                const Text(
                  'Opciones encontradas',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 14),

                // SIN RESULTADOS
                if (accommodations.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          color: AppTheme.textSecondary,
                          size: 48,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'No se encontraron alojamientos disponibles para esta búsqueda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                // RESULTADOS
                else
                  ...accommodations.map(
                    (accommodation) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _AccommodationCard(accommodation: accommodation),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccommodationCard extends StatelessWidget {
  const _AccommodationCard({required this.accommodation});

  final Accommodation accommodation;

  @override
  Widget build(BuildContext context) {
    final typeLabel =
        accommodation.type == AccommodationType.apartment
            ? 'Apartamento'
            : 'Pensionado';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      AccommodationDetailPage(accommodation: accommodation),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE7EBEF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITULO Y UBICACION
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: AppTheme.navy,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accommodation.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppTheme.textSecondary,
                              size: 17,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                accommodation.location,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.navy,
                    size: 28,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // CARACTERISTICAS
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(icon: Icons.apartment_rounded, text: typeLabel),
                  _InfoChip(
                    icon: Icons.bathroom_outlined,
                    text: '${accommodation.bathrooms} baño(s)',
                  ),
                  _InfoChip(
                    icon: Icons.square_foot,
                    text:
                        '${accommodation.sizeSquareMeters.toStringAsFixed(0)} m²',
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Divider(),

              const SizedBox(height: 12),

              // PRECIO Y DISPONIBILIDAD
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Precio mensual',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Q${accommodation.monthlyPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.navy,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

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

              const SizedBox(height: 14),

              Row(
                children: [
                  const Spacer(),
                  Text(
                    'Ver detalles',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.navy,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.navy),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
