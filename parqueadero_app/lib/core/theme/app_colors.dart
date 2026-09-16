import 'package:flutter/material.dart';

/// Los ocho tokens de marca del sistema de diseño (skill
/// `diseno-parqueadero`): la identidad sale del objeto real — asfalto oscuro
/// con demarcación amarilla pintada. Único lugar del proyecto que declara
/// estos hex; `app_theme.dart` los vuelca en un `ColorScheme` explícito (no
/// `ColorScheme.fromSeed`, que generaría tonos más vivos de lo que pide este
/// diseño), derivando ahí los pocos tonos intermedios que Material exige y
/// que no tienen un token 1:1.
///
/// Reforma "Asfalto y Demarcación" (2026-09-15): el tema pasó de superficie
/// clara a oscura y la paleta pasó de seis tokens a estos ocho. Los tres
/// tonos de asfalto son las superficies (fondo raíz, tarjetas, bordes) y el
/// resto son los acentos y el texto que viven sobre ellas.
///
/// Deliberadamente separada de la paleta de estados (`status_style.dart`),
/// que es más saturada y nunca debe confundirse con esta.
class AppColors {
  const AppColors._();

  static const asfaltoOscuro = Color(0xFF1A1A1A);
  static const asfaltoMedio = Color(0xFF2B2B2B);
  static const asfaltoClaro = Color(0xFF3D3D3D);
  static const amarilloPastel = Color(0xFFF2E85C);
  static const verdePastel = Color(0xFF9BCD9B);
  static const blancoHueso = Color(0xFFF5F5F0);
  static const grisClaro = Color(0xFFB0B0A8);
  static const terracota = Color(0xFFD97A5A);
}
