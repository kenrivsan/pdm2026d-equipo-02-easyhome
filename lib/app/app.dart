import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerWidget, ProviderScope, WidgetRef, Ref;
import 'package:provider/provider.dart';

import '../features/accommodations/data/datasources/location_data_source.dart';
import '../features/accommodations/data/repositories/location_repository_impl.dart';
import '../features/accommodations/data/repositories/shared_catalog_reader.dart';
import '../features/accommodations/domain/repositories/location_repository.dart';
import '../features/accommodations/presentation/controllers/accommodation_search_controller.dart';
import '../features/accommodations/presentation/controllers/catalog_deletion_provider.dart';
import '../features/accommodations/presentation/controllers/catalog_providers.dart';
import '../features/accommodations/presentation/providers/shared_accommodation_providers.dart';
import '../features/auth/presentation/pages/login_page.dart';
import 'accommodation_deletion_providers.dart';
import 'theme/app_theme.dart';

class EasyHomeApp extends StatelessWidget {
  const EasyHomeApp({super.key});

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      catalogReaderProvider.overrideWith(_createCatalogReader),
      catalogDeletionControllerProvider.overrideWith(
        createSharedAccommodationDeletionController,
      ),
      ownerAccommodationDeletionControllerProvider.overrideWith(
        createSharedAccommodationDeletionController,
      ),
    ],
    child: const _EasyHomeProviders(),
  );
}

SharedCatalogReader _createCatalogReader(Ref ref) =>
    SharedCatalogReader(ref.watch(sharedAccommodationRepositoryProvider));

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
