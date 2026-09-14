import 'package:flutter/material.dart';

/// Tipografía para montos destacados — el color se aplica en cada superficie
/// con `copyWith(color: ...)`, porque el mismo monto puede aparecer sobre
/// fondos distintos.
class AppTypography {
  const AppTypography._();

  static const montoDestacado = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );
}
