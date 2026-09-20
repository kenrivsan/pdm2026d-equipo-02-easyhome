import 'package:flutter/material.dart';

import 'search_page.dart';

class AccommodationsPage extends StatelessWidget {
  const AccommodationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Easy Home'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchPage(),
              ),
            );
          },
          child: const Text('Buscar alojamiento'),
        ),
      ),
    );
  }
}
