import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/bogota_time.dart';
import '../../../../core/utils/money.dart';
import '../../../tickets/domain/pago.dart';
import '../../../tickets/presentation/widgets/metodo_pago_label.dart';
import '../../domain/arqueo_turno.dart';
import '../../domain/turno.dart';
import 'diferencia_texto.dart';

/// Resumen de caja de un turno, en vivo (ABIERTO) o final (CERRADO). Se
/// reutiliza tal cual desde `TurnoDetailScreen` y desde el resultado del
/// cierre en `TurnoCierreScreen`: mismo objeto [ArqueoTurno], un solo widget.
/// La diferencia se muestra sin juicio de valor: mismo tono para sobrante,
/// faltante o cuadre exacto, con el signo explícito en el texto.
class ArqueoSummaryView extends StatelessWidget {
  const ArqueoSummaryView({super.key, required this.arqueo});

  final ArqueoTurno arqueo;

  @override
  Widget build(BuildContext context) {
    final totales = arqueo.totalesPorMetodo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              switch (arqueo.estado) {
                EstadoTurno.abierto => 'Arqueo en vivo',
                EstadoTurno.cerradoPendienteArqueo => 'Arqueo pendiente de completar',
                EstadoTurno.cerrado => 'Arqueo final',
              },
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _Fila('Apertura', formatBogota(arqueo.apertura)),
            _Fila('Cierre', arqueo.cierre == null ? 'Turno en curso' : formatBogota(arqueo.cierre!)),
            const Divider(height: AppSpacing.lg),
            _Fila('Base inicial', formatMoney(arqueo.baseInicial)),
            _Fila(metodoPagoLabel(MetodoPago.efectivo), formatMoney(totales.efectivo)),
            _Fila(metodoPagoLabel(MetodoPago.tarjeta), formatMoney(totales.tarjeta)),
            _Fila(metodoPagoLabel(MetodoPago.transferencia), formatMoney(totales.transferencia)),
            _Fila('Total recaudado', formatMoney(arqueo.totalRecaudado), destacado: true),
            _Fila('Tickets cerrados', '${arqueo.ticketsCerrados}'),
            const Divider(height: AppSpacing.lg),
            _Fila('Efectivo esperado', formatMoney(arqueo.efectivoEsperado)),
            _Fila(
              'Efectivo contado',
              arqueo.efectivoContado == null ? 'Aún no contado' : formatMoney(arqueo.efectivoContado!),
            ),
            _Fila(
              'Diferencia',
              arqueo.diferencia == null ? 'Aún no calculada' : diferenciaTexto(arqueo.diferencia!),
              destacado: true,
            ),
            if (arqueo.validadoEn != null) ...[
              const Divider(height: AppSpacing.lg),
              _Fila('Arqueo validado', formatBogota(arqueo.validadoEn!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.label, this.valor, {this.destacado = false});

  final String label;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final estilo = destacado
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: estilo),
          Text(valor, style: estilo),
        ],
      ),
    );
  }
}
