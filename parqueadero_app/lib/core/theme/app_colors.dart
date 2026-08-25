import 'package:flutter/material.dart';

/// Los seis tokens de marca del sistema de diseño (skill
/// `diseno-parqueadero`): la identidad sale del objeto real — asfalto oscuro
/// con demarcación amarilla pintada. Único lugar del proyecto que declara
/// estos hex; `app_theme.dart` los vuelca en un `ColorScheme` explícito (no
/// `ColorScheme.fromSeed`, que generaría tonos más vivos de lo que pide este
/// diseño), derivando ahí los pocos tonos intermedios que Material exige y
/// que no tienen un token 1:1.
///
/// Deliberadamente separada de la paleta de estados (`status_style.dart`),
/// que es más saturada y nunca debe confundirse con esta.
///
/// `demarcacion` está declarada pero, por ahora, ningún rol del
/// `ColorScheme` general la usa: la skill es explícita en que solo vive
/// sobre `asfalto` o como línea/borde/relleno, y que la audacia se
/// concentra en la cuadrícula de celdas — todo lo demás debe quedar
/// tranquilo. Queda lista para cuando se rediseñe la cuadrícula.
class AppColors {
  const AppColors._();

  static const asfalto = Color(0xFF101A14);
  static const verdeSenal = Color(0xFF1B6B45);
  static const demarcacion = Color(0xFFF2C230);
  static const concreto = Color(0xFFF8F7F2);
  static const linea = Color(0xFFE3E0D6);
  static const tinta = Color(0xFF12150F);
}
