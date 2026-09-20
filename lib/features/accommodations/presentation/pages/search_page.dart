import 'package:flutter/material.dart';

import '../../data/datasources/location_data_source.dart';
import '../../data/models/department_model.dart';
import '../../data/models/university_model.dart';
import 'results_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final LocationDataSource _locationDataSource = InMemoryLocationDataSource();

  List<DepartmentModel> _departments = [];
  List<UniversityModel> _universities = [];

  String? _selectedDepartmentId;
  String? _selectedUniversityId;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final departments = await _locationDataSource.getDepartments();
    final universities = await _locationDataSource.getUniversities();

    setState(() {
      _departments = departments;
      _universities = universities;
    });
  }

  List<UniversityModel> get _filteredUniversities {
    return _universities
        .where(
          (university) =>
              university.departmentId == _selectedDepartmentId,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar alojamiento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Departamento',
                border: OutlineInputBorder(),
              ),
              value: _selectedDepartmentId,
              items: _departments.map((department) {
                return DropdownMenuItem(
                  value: department.id,
                  child: Text(department.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartmentId = value;
                  _selectedUniversityId = null;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Universidad',
                border: OutlineInputBorder(),
              ),
              value: _selectedUniversityId,
              items: _filteredUniversities.map((university) {
                return DropdownMenuItem(
                  value: university.id,
                  child: Text(university.name),
                );
              }).toList(),
              onChanged: _selectedDepartmentId == null
                  ? null
                  : (value) {
                      setState(() {
                        _selectedUniversityId = value;
                      });
                    },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _selectedDepartmentId != null &&
                      _selectedUniversityId != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResultsPage(),
                        ),
                      );
                    }
                  : null,
              child: const Text('Ver resultados'),
            ),
          ],
        ),
      ),
    );
  }
}