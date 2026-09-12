import 'package:flutter/material.dart';

/// Spinner para el estado de carga de un botón (`ElevatedButton`/`OutlinedButton`),
/// en vez de repetir `SizedBox(height: N, width: N, child: CircularProgressIndicator(...))`
/// en cada pantalla.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, this.size = 24, this.color});

  final double size;

  /// `CircularProgressIndicator` no hereda el `foregroundColor` del botón que
  /// lo envuelve (solo texto e íconos lo hacen): un botón con fondo distinto
  /// al `colorScheme.primary` de siempre necesita pasar este color a mano
  /// para que el spinner no quede invisible sobre su propio fondo.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
    );
  }
}
