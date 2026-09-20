import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/accommodations/data/datasources/accommodation_data_source.dart';
import '../features/accommodations/data/datasources/location_data_source.dart';
import '../features/accommodations/data/repositories/accommodation_repository_impl.dart';
import '../features/accommodations/data/repositories/location_repository_impl.dart';
import '../features/accommodations/domain/repositories/accommodation_repository.dart';
import '../features/accommodations/domain/repositories/location_repository.dart';
import '../features/accommodations/presentation/controllers/accommodation_search_controller.dart';
import '../features/accommodations/presentation/pages/accommodations_page.dart';
import 'theme/app_theme.dart';

class EasyHomeApp extends StatelessWidget {
  const EasyHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AccommodationRepository>(
          create:
              (_) => AccommodationRepositoryImpl(
                InMemoryAccommodationDataSource(),
              ),
        ),
        Provider<LocationRepository>(
          create: (_) => LocationRepositoryImpl(InMemoryLocationDataSource()),
        ),
        ChangeNotifierProvider(
          create:
              (context) => AccommodationSearchController(
                accommodationRepository:
                    context.read<AccommodationRepository>(),
                locationRepository: context.read<LocationRepository>(),
              )..loadData(),
        ),
      ],
      child: MaterialApp(
        title: 'Easy Home',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AccommodationsPage(),
      ),
    );
  }
}
