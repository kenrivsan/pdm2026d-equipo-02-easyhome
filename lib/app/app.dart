import 'package:flutter/material.dart';

import '../features/accommodations/presentation/pages/accommodations_page.dart';
import 'theme/app_theme.dart';

class EasyHomeApp extends StatelessWidget {
  const EasyHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Home',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AccommodationsPage(),
    );
  }
}
