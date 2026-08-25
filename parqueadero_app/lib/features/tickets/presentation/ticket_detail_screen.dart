import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/bogota_time.dart';
import '../../../core/utils/tipo_vehiculo_label.dart';
import '../../../core/widgets/detail_skeleton.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/material_hero.dart';
import '../domain/ticket.dart';
import 'ticket_detail_notifier.dart';
import 'widgets/desglose_view.dart';
import 'widgets/metodo_pago_label.dart';
import 'widgets/ticket_estado_chip.dart';

class TicketDetailScreen extends ConsumerWidget {
  const TicketDetailScreen({super.key, required this.ticketId, this.ticketInicial});

  final String ticketId;

  /// El ticket ya conocido en el momento del tap (viene del listado, por
  /// `extra` en la ruta). Se usa solo para pintar de entrada el chip de
  /// estado con su `Hero` ya en su lugar, mientras
  /// `ticket_detail_notifier.dart` confirma el resto — sin esto el `Hero`
  /// no tendría destino durante el primer frame, mientras la pantalla
  /// todavía está cargando.
  final Ticket? ticketInicial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ticketDetailNotifierProvider(ticketId));
    final notifier = ref.read(ticketDetailNotifierProvider(ticketId).notifier);

    Widget body;
    if (state.isLoading && ticketInicial == null) {
      body = const DetailSkeleton(lineas: 6);
    } else if (state.errorMessage != null) {
      body = ErrorState(message: state.errorMessage!, onRetry: notifier.cargar);
    } else if (state.isLoading) {
      body = ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          MaterialHero(
            tag: 'ticket-estado-$ticketId',
            child: TicketEstadoChip(estado: ticketInicial!.estado),
          ),
          const SizedBox(height: AppSpacing.lg),
          const DetailSkeleton(lineas: 5),
        ],
      );
    } else {
      final ticket = state.ticket!;
      body = ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          MaterialHero(tag: 'ticket-estado-$ticketId', child: TicketEstadoChip(estado: ticket.estado)),
          const SizedBox(height: AppSpacing.md),
          Text('Código: ${ticket.codigo}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('Placa: ${ticket.vehiculo?.placa ?? '—'}'),
          if (ticket.vehiculo != null) Text('Tipo: ${tipoVehiculoLabel(ticket.vehiculo!.tipo)}'),
          Text('Celda: ${ticket.celda?.codigo ?? '—'}'),
          const SizedBox(height: AppSpacing.sm),
          Text('Entrada: ${formatBogota(ticket.horaEntrada)}'),
          Text('Salida: ${ticket.horaSalida != null ? formatBogota(ticket.horaSalida!) : '—'}'),
          if (ticket.pago != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Método de pago: ${metodoPagoLabel(ticket.pago!.metodo)}'),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (ticket.valorTotal == null)
            Text(
              'Ticket aún abierto, sin cobro registrado.',
              style: Theme.of(context).textTheme.bodyLarge,
            )
          else
            DesgloseView(desglose: ticket.desglose, valorTotal: ticket.valorTotal!),
          if (ticket.recibo != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => context.push('/tickets/$ticketId/recibo'),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Ver recibo'),
            ),
          ],
        ],
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Detalle del ticket')), body: body);
  }
}
