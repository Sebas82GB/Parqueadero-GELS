import 'package:flutter/material.dart';

import '../../../../core/theme/status_style.dart';
import '../../domain/ticket.dart';

/// El color sale de `StatusStyle` (paleta de estados centralizada, separada
/// de la de marca) — mismo criterio que `CeldaEstadoStyle`. El estado nunca
/// se comunica solo por color: siempre va acompañado del ícono y la
/// etiqueta de aquí.
class TicketEstadoStyle {
  const TicketEstadoStyle._(this.color, this.icon, this.label);

  final Color color;
  final IconData icon;
  final String label;

  static TicketEstadoStyle of(EstadoTicket estado) => switch (estado) {
    EstadoTicket.abierto => TicketEstadoStyle._(
      StatusStyle.of(StatusTone.info).color,
      Icons.timelapse,
      'Abierto',
    ),
    EstadoTicket.pagado => TicketEstadoStyle._(
      StatusStyle.of(StatusTone.success).color,
      Icons.check_circle,
      'Pagado',
    ),
    EstadoTicket.entregado => TicketEstadoStyle._(
      StatusStyle.of(StatusTone.neutral).color,
      Icons.task_alt,
      'Entregado',
    ),
    EstadoTicket.anulado => TicketEstadoStyle._(
      StatusStyle.of(StatusTone.danger).color,
      Icons.cancel,
      'Anulado',
    ),
  };
}
