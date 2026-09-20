
import 'package:flutter/material.dart';

import 'results_page.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar alojamiento'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ResultsPage(),
              ),
            );
          },
          child: const Text('Ver resultados'),
        ),
      ),
    );
  }
}