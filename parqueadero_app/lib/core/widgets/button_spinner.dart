import 'package:flutter/material.dart';

/// Spinner para el estado de carga de un botón (`ElevatedButton`/`OutlinedButton`),
/// en vez de repetir `SizedBox(height: N, width: N, child: CircularProgressIndicator(...))`
/// en cada pantalla.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: size, width: size, child: const CircularProgressIndicator(strokeWidth: 2.5));
  }
}
