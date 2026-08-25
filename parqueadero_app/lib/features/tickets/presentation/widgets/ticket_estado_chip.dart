import 'package:flutter/material.dart';

import '../../domain/ticket.dart';
import 'ticket_estado_style.dart';

class TicketEstadoChip extends StatelessWidget {
  const TicketEstadoChip({super.key, required this.estado});

  final EstadoTicket estado;

  @override
  Widget build(BuildContext context) {
    final style = TicketEstadoStyle.of(estado);
    return Chip(
      avatar: Icon(style.icon, color: style.color, size: 18),
      label: Text(style.label),
      backgroundColor: style.color.withValues(alpha: 0.12),
      side: BorderSide(color: style.color.withValues(alpha: 0.4)),
    );
  }
}
