import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/owner_accommodation_store.dart';
import '../controllers/accommodation_search_controller.dart';

class AddAccommodationPage extends StatefulWidget {
  const AddAccommodationPage({super.key});

  @override
  State<AddAccommodationPage> createState() => _AddAccommodationPageState();
}

class _AddAccommodationPageState extends State<AddAccommodationPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _bathrooms = TextEditingController();
  final _size = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();

  String _type = 'Apartamento';
  String? _departmentId;
  String? _universityId;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _price.dispose();
    _description.dispose();
    _bathrooms.dispose();
    _size.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  void _publish() {
    if (!_formKey.currentState!.validate()) return;

    if (_departmentId == null || _universityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona departamento y universidad')),
      );
      return;
    }

    final controller = context.read<AccommodationSearchController>();

    final accommodation = OwnerAccommodation(
      id: 'owner-${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      type: _type,
      address: _address.text.trim(),
      departmentId: _departmentId!,
      universityIds: [_universityId!],
      monthlyPrice: double.parse(_price.text.trim().replaceAll(',', '.')),
      description: _description.text.trim(),
      bathrooms: int.parse(_bathrooms.text.trim()),
      sizeSquareMeters: double.parse(_size.text.trim().replaceAll(',', '.')),
      contactName: _contactName.text.trim(),
      contactPhone: _contactPhone.text.trim(),
    );

    OwnerAccommodationStore.instance.add(accommodation);
    controller.refreshAccommodations();

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AccommodationSearchController>();

    final universities =
        controller.universities
            .where((university) => university.departmentId == _departmentId)
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar alojamiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.add_home_work_rounded,
                    size: 65,
                    color: AppTheme.navy,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Publica tu alojamiento',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 25),

                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del alojamiento',
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Ingresa el nombre'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de alojamiento',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Apartamento',
                        child: Text('Apartamento'),
                      ),
                      DropdownMenuItem(
                        value: 'Pensionado',
                        child: Text('Pensionado'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _type = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    key: ValueKey('department-$_departmentId'),
                    initialValue: _departmentId,
                    decoration: const InputDecoration(
                      labelText: 'Departamento',
                    ),
                    items:
                        controller.departments.map((department) {
                          return DropdownMenuItem(
                            value: department.id,
                            child: Text(department.name),
                          );
                        }).toList(),
                    validator:
                        (value) =>
                            value == null ? 'Selecciona un departamento' : null,
                    onChanged: (value) {
                      setState(() {
                        _departmentId = value;
                        _universityId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    key: ValueKey('university-$_departmentId'),
                    initialValue: _universityId,
                    decoration: const InputDecoration(
                      labelText: 'Universidad cercana',
                    ),
                    items:
                        universities.map((university) {
                          return DropdownMenuItem(
                            value: university.id,
                            child: Text(university.name),
                          );
                        }).toList(),
                    validator:
                        (value) =>
                            value == null ? 'Selecciona una universidad' : null,
                    onChanged:
                        _departmentId == null
                            ? null
                            : (value) {
                              setState(() {
                                _universityId = value;
                              });
                            },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Ingresa la dirección'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio mensual (L)',
                    ),
                    validator: (value) {
                      final price = double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      );
                      if (price == null || !price.isFinite || price <= 0) {
                        return 'Ingresa un precio válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _bathrooms,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad de baños',
                    ),
                    validator: (value) {
                      final number = int.tryParse((value ?? '').trim());
                      if (number == null || number <= 0) {
                        return 'Ingresa una cantidad válida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _size,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Tamaño en metros cuadrados',
                    ),
                    validator: (value) {
                      final size = double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      );
                      if (size == null || !size.isFinite || size <= 0) {
                        return 'Ingresa un tamaño válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _contactName,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del contacto',
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Ingresa el nombre del contacto'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _contactPhone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono de contacto',
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Ingresa un teléfono'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descripción del alojamiento',
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Ingresa una descripción'
                                : null,
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _publish,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Publicar alojamiento'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
