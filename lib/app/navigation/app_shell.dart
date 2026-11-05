import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accommodations/presentation/pages/accommodations_page.dart';
import '../../features/accommodations/presentation/pages/owner_home_page.dart';
import '../../features/accommodations/presentation/pages/results_page.dart';
import '../../features/accommodations/presentation/pages/search_page.dart';
import 'app_navigation.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(appNavigationProvider);

    return Scaffold(
      body: IndexedStack(
        index: activeTab.index,
        children: const [
          AccommodationsPage(),
          SearchPage(),
          ResultsPage(),
          OwnerHomePage(),
          Scaffold(body: Center(child: Text('Ajustes: Próximamente'))),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTab.index,
        onDestinationSelected:
            (index) => ref
                .read(appNavigationProvider.notifier)
                .select(AppTab.values[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(
            icon: Icon(Icons.apartment),
            label: 'Alojamientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_home_outlined),
            label: 'Propietario',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
