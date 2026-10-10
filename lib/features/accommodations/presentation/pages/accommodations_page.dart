import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import 'owner_home_page.dart';
import 'search_page.dart';

class AccommodationsPage extends StatelessWidget {
  const AccommodationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 55, 24, 60),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.navy, AppTheme.navyDark],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.home_work_rounded, color: Colors.white, size: 58),
                  SizedBox(height: 18),
                  Text(
                    'Easy Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Encuentra o publica un lugar '
                    'cerca de tu universidad',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFDDEAF6),
                      fontSize: 17,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    children: [
                      const Text(
                        '¿Cómo deseas continuar?',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Selecciona el tipo de usuario '
                        'que mejor describe lo que necesitas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _UserOptionCard(
                        icon: Icons.school_rounded,
                        title: 'Soy estudiante',
                        subtitle:
                            'Busca apartamentos y pensionados '
                            'cerca de tu universidad.',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchPage(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      _UserOptionCard(
                        icon: Icons.home_work_rounded,
                        title: 'Soy propietario',
                        subtitle:
                            'Publica y administra tus '
                            'alojamientos disponibles.',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OwnerHomePage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserOptionCard extends StatelessWidget {
  const _UserOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE7EBEF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: AppTheme.navy, size: 31),
              ),

              const SizedBox(width: 17),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.navy,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
