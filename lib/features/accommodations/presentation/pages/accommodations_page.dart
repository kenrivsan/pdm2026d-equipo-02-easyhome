import 'package:flutter/material.dart';

import '../../../../shared/widgets/empty_state.dart';

class AccommodationsPage extends StatelessWidget {
  const AccommodationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Easy Home')),
      body: const EmptyState(
        title: 'Búsqueda de alojamientos',
        message: 'La pantalla del MVP se implementará en los issues de producto.',
      ),
    );
  }
}
