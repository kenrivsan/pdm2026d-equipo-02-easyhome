import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel del propietario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.navy, AppTheme.navyDark],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.home_work_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Gestiona tus alojamientos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Publica y administra los alojamientos '
                        'que deseas ofrecer a estudiantes.',
                        style: TextStyle(
                          color: Color(0xFFDDEAF6),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  '¿Qué deseas hacer?',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 16),

                _OwnerOption(
                  icon: Icons.add_home_work_outlined,
                  title: 'Agregar alojamiento',
                  subtitle: 'Publica un apartamento o pensionado.',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Formulario de alojamiento será el siguiente paso.',
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                _OwnerOption(
                  icon: Icons.apartment_rounded,
                  title: 'Mis alojamientos',
                  subtitle: 'Consulta y administra tus publicaciones.',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Listado del propietario será el siguiente paso.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerOption extends StatelessWidget {
  const _OwnerOption({
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
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7EBEF)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppTheme.navy, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.navy),
            ],
          ),
        ),
      ),
    );
  }
}
