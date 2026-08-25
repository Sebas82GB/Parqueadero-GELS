import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/bogota_time.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/material_hero.dart';
import '../../domain/ticket.dart';
import 'ticket_estado_chip.dart';

class TicketListItem extends StatelessWidget {
  const TicketListItem({super.key, required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push('/tickets/${ticket.id}', extra: ticket),
        title: Text(ticket.vehiculo?.placa ?? '—'),
        subtitle: Text(
          'Celda ${ticket.celda?.codigo ?? '—'} · ${formatBogota(ticket.horaEntrada)}'
          '${ticket.valorTotal != null ? ' · ${formatMoney(ticket.valorTotal!)}' : ''}',
        ),
        trailing: MaterialHero(
          tag: 'ticket-estado-${ticket.id}',
          child: TicketEstadoChip(estado: ticket.estado),
        ),
      ),
    );
  }
}
