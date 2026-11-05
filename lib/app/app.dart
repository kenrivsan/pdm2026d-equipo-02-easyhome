import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerWidget, ProviderScope, WidgetRef;
import 'package:provider/provider.dart';

import '../features/accommodations/data/datasources/location_data_source.dart';
import '../features/accommodations/data/repositories/location_repository_impl.dart';
import '../features/accommodations/domain/repositories/location_repository.dart';
import '../features/accommodations/presentation/controllers/accommodation_search_controller.dart';
import '../features/accommodations/presentation/providers/shared_accommodation_providers.dart';
import '../features/auth/presentation/pages/login_page.dart';
import 'theme/app_theme.dart';

class EasyHomeApp extends StatelessWidget {
  const EasyHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(child: const _EasyHomeProviders());
  }
}

class _EasyHomeProviders extends ConsumerWidget {
  const _EasyHomeProviders();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedRepository = ref.watch(sharedAccommodationRepositoryProvider);

    return MultiProvider(
      providers: [
        Provider<LocationRepository>(
          create: (_) => LocationRepositoryImpl(InMemoryLocationDataSource()),
        ),
        ChangeNotifierProvider(
          create:
              (context) => AccommodationSearchController(
                sharedAccommodationRepository: sharedRepository,
                locationRepository: context.read<LocationRepository>(),
              )..loadData(),
        ),
      ],
      child: MaterialApp(
        title: 'Easy Home',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const LoginPage(),
      ),
    );
  }
}
