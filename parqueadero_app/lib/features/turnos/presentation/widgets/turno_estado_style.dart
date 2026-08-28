import 'package:flutter/material.dart';

import '../../../../core/theme/status_style.dart';
import '../../domain/turno.dart';

/// El color sale de `StatusStyle` (paleta de estados centralizada), mismo
/// criterio que `TicketEstadoStyle`/`CeldaEstadoStyle`. El estado nunca se
/// comunica solo por color: siempre va acompañado del ícono y la etiqueta.
class TurnoEstadoStyle {
  const TurnoEstadoStyle._(this.color, this.icon, this.label);

  final Color color;
  final IconData icon;
  final String label;

  static TurnoEstadoStyle of(EstadoTurno estado) => switch (estado) {
    EstadoTurno.abierto => TurnoEstadoStyle._(StatusStyle.of(StatusTone.info).color, Icons.timelapse, 'Abierto'),
    EstadoTurno.cerradoPendienteArqueo => TurnoEstadoStyle._(
      StatusStyle.of(StatusTone.warning).color,
      Icons.pending_actions,
      'Pendiente de arqueo',
    ),
    EstadoTurno.cerrado => TurnoEstadoStyle._(
      StatusStyle.of(StatusTone.neutral).color,
      Icons.task_alt,
      'Cerrado',
    ),
  };
}
