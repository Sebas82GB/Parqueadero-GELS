import 'package:flutter/material.dart';

import '../../domain/mensualidad.dart';
import 'vigencia_style.dart';

class VigenciaChip extends StatelessWidget {
  const VigenciaChip({super.key, required this.vigencia});

  final VigenciaMensualidad vigencia;

  @override
  Widget build(BuildContext context) {
    final style = VigenciaStyle.of(vigencia);
    // Sin labelStyle teñido (ver celda_card.dart): el fondo y el borde ya
    // comunican el estado, el texto se queda en el color por defecto.
    return Chip(
      label: Text(style.label),
      backgroundColor: style.color.withValues(alpha: 0.12),
      side: BorderSide(color: style.color.withValues(alpha: 0.4)),
    );
  }
}
