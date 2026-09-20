import 'package:flutter/material.dart';

import '../../../../shared/widgets/empty_state.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de búsqueda'),
      ),
      body: const EmptyState(
        title: 'Alojamientos disponibles',
        message:
            'Aquí se mostrarán los apartamentos y pensionados disponibles.',
      ),
    );
  }
}