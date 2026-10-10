
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../accommodations/presentation/pages/accommodations_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();

  bool _mostrarContrasena = false;

  // Usuario ficticio para demostrar el MVP.
  static const correoDemo = 'demo@ingenium.com';
  static const contrasenaDemo = 'EasyHome123';

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  void _iniciarSesion() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final correo = _correo.text.trim().toLowerCase();
    final contrasena = _contrasena.text;

    if (correo == correoDemo && contrasena == contrasenaDemo) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AccommodationsPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo o contraseña incorrectos'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final alturaEncabezado =
                (constraints.maxHeight * 0.38)
                    .clamp(220.0, 300.0)
                    .toDouble();

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Parte superior azul de la plantilla.
                  Container(
                    width: double.infinity,
                    height: alturaEncabezado,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.navyDark,
                          AppTheme.navy,
                        ],
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¡BIENVENIDO!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: 25),

                        Icon(
                          Icons.home_work_rounded,
                          size: 85,
                          color: Colors.white,
                        ),

                        SizedBox(height: 12),

                        Text(
                          'EASY HOME',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          'INGENIUM',
                          style: TextStyle(
                            color: AppTheme.cyan,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Parte blanca del formulario.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight - alturaEncabezado,
                    ),
                    child: Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 35,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 360,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'INICIAR SESIÓN',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.navy,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                const Text(
                                  'Ingresa tus datos para continuar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(height: 28),

                                TextFormField(
                                  controller: _correo,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Correo electrónico',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                    ),
                                  ),
                                  validator: (valor) {
                                    final correo = valor?.trim() ?? '';

                                    if (correo.isEmpty) {
                                      return 'Ingresa tu correo';
                                    }

                                    if (!RegExp(
                                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                    ).hasMatch(correo)) {
                                      return 'Correo no válido';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _contrasena,
                                  obscureText: !_mostrarContrasena,
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _mostrarContrasena
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _mostrarContrasena =
                                              !_mostrarContrasena;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (valor) {
                                    if (valor == null ||
                                        valor.isEmpty) {
                                      return 'Ingresa tu contraseña';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) {
                                    _iniciarSesion();
                                  },
                                ),

                                const SizedBox(height: 25),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _iniciarSesion,
                                    child: const Text(
                                      'INICIAR SESIÓN',
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 25),

                                const Text(
                                  'CUENTA DE DEMOSTRACIÓN',
                                  style: TextStyle(
                                    color: AppTheme.navy,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                const Text(
                                  'Correo: demo@ingenium.com\n'
                                  'Contraseña: EasyHome123',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                ),

                                const SizedBox(height: 30),

                                const Text(
                                  'Desarrollado por INGENIUM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
