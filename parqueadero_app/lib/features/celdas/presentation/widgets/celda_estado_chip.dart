import 'package:flutter/material.dart';

import '../../domain/celda.dart';
import 'celda_estado_style.dart';

class CeldaEstadoChip extends StatelessWidget {
  const CeldaEstadoChip({super.key, required this.estado});

  final EstadoCelda estado;

  @override
  Widget build(BuildContext context) {
    final style = CeldaEstadoStyle.of(estado);
    return Chip(
      avatar: Icon(style.icon, color: style.color, size: 18),
      label: Text(style.label),
      backgroundColor: style.color.withValues(alpha: 0.12),
      side: BorderSide(color: style.color.withValues(alpha: 0.4)),
    );
  }
}
