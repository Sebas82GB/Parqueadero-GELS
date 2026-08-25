import 'package:flutter/material.dart';

/// Duraciones y curva de todo movimiento en la app. Es una herramienta de
/// trabajo, no una app de consumo: duraciones cortas, una sola curva suave
/// (nunca `bounceOut`/`elasticOut`/`anticipate` — nada rebota ni llama la
/// atención de más).
class AppMotion {
  const AppMotion._();

  /// Cambios pequeños y frecuentes: el color/ícono de una celda del grid al
  /// cambiar de estado.
  static const fast = Duration(milliseconds: 150);

  /// Transición de página (`AppPageTransitionsBuilder`).
  static const medium = Duration(milliseconds: 200);

  /// Superficies grandes: diálogos, sheets.
  static const slow = Duration(milliseconds: 250);

  static const curve = Curves.easeInOutCubic;

  /// Único punto que toda animación nueva debe consultar para respetar la
  /// preferencia de movimiento reducido del sistema: devuelve
  /// [Duration.zero] si está activa, o [normal] si no.
  static Duration effective(BuildContext context, Duration normal) =>
      MediaQuery.of(context).disableAnimations ? Duration.zero : normal;
}
