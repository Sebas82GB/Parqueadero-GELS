import 'package:flutter/material.dart';

/// Pantalla genérica mientras la app valida algo antes de decidir a dónde
/// navegar (hoy: la sesión guardada al arrancar).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
