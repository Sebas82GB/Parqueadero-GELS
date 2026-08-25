import 'package:flutter/material.dart';

import '../../../../core/theme/status_style.dart';
import '../../domain/celda.dart';

/// El color de cada estado sale de `StatusStyle` (paleta de estados
/// centralizada, separada de la de marca): esta clase solo mapea el enum de
/// dominio a un ícono más específico que el genérico del tono y a su
/// etiqueta. El estado nunca se comunica solo por color: siempre va
/// acompañado del ícono y la etiqueta de aquí.
class CeldaEstadoStyle {
  const CeldaEstadoStyle._(this.color, this.icon, this.label);

  final Color color;
  final IconData icon;
  final String label;

  static CeldaEstadoStyle of(EstadoCelda estado) => switch (estado) {
    EstadoCelda.libre => CeldaEstadoStyle._(
      StatusStyle.of(StatusTone.success).color,
      Icons.check_circle,
      'Libre',
    ),
    EstadoCelda.ocupada => CeldaEstadoStyle._(
      StatusStyle.of(StatusTone.danger).color,
      Icons.directions_car,
      'Ocupada',
    ),
    EstadoCelda.mantenimiento => CeldaEstadoStyle._(
      StatusStyle.of(StatusTone.warning).color,
      Icons.build,
      'Mantenimiento',
    ),
  };
}
