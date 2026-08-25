import 'package:flutter/material.dart';

import '../../domain/mensualidad.dart';
import 'estado_pago_style.dart';

class EstadoPagoChip extends StatelessWidget {
  const EstadoPagoChip({super.key, required this.estado});

  final EstadoPagoMensualidad estado;

  @override
  Widget build(BuildContext context) {
    final style = EstadoPagoStyle.of(estado);
    // Sin labelStyle teñido (ver celda_card.dart): el fondo y el borde ya
    // comunican el estado, el texto se queda en el color por defecto.
    return Chip(
      label: Text(style.label),
      backgroundColor: style.color.withValues(alpha: 0.12),
      side: BorderSide(color: style.color.withValues(alpha: 0.4)),
    );
  }
}
