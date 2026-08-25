import 'package:flutter/material.dart';

import '../../domain/turno.dart';
import 'turno_estado_style.dart';

class TurnoEstadoChip extends StatelessWidget {
  const TurnoEstadoChip({super.key, required this.estado});

  final EstadoTurno estado;

  @override
  Widget build(BuildContext context) {
    final style = TurnoEstadoStyle.of(estado);
    return Chip(
      avatar: Icon(style.icon, color: style.color, size: 18),
      label: Text(style.label),
      backgroundColor: style.color.withValues(alpha: 0.12),
      side: BorderSide(color: style.color.withValues(alpha: 0.4)),
    );
  }
}
