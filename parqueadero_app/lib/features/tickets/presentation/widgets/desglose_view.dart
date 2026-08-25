import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/bogota_time.dart';
import '../../../../core/utils/money.dart';
import '../../domain/desglose_item.dart';

/// El desglose se muestra tal como lo devuelve el backend — ninguna regla de
/// cobro se recalcula acá (regla de CLAUDE.md). El operador tiene que poder
/// explicarle al cliente de dónde salió cada valor, por eso cada bloque
/// aparece con su horario y tipo de cobro, no solo el total.
class DesgloseView extends StatelessWidget {
  const DesgloseView({super.key, required this.desglose, required this.valorTotal});

  final List<DesgloseItem> desglose;

  /// Null solo en un preview de un vehículo OTRO: todavía no hay un monto
  /// que mostrar (ver [DesgloseManual.motivo]).
  final int? valorTotal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in desglose) _filaDesglose(context, item),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: Theme.of(context).textTheme.titleMedium),
            Text(
              valorTotal != null ? formatMoney(valorTotal!) : 'Por definir',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ],
    );
  }

  Widget _filaDesglose(BuildContext context, DesgloseItem item) => switch (item) {
    DesgloseMensualidad() => _fila(
      context,
      titulo: 'Cubierto por mensualidad vigente',
      valor: item.valor,
    ),
    DesgloseManual() => _fila(
      context,
      titulo: 'Valor manual',
      subtitulo: item.motivo,
      valor: item.valor,
    ),
    DesgloseBloque() => _fila(
      context,
      titulo: 'Día ${item.dia} · bloque ${item.bloqueNumero} · ${_tipoCobroLabel(item.tipoCobro)}',
      subtitulo: '${formatBogota(item.inicio, 'h:mm a')} – ${formatBogota(item.fin, 'h:mm a')} · ${item.minutos} min',
      valor: item.valor,
    ),
  };

  Widget _fila(BuildContext context, {required String titulo, String? subtitulo, required int? valor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.bodyLarge),
                if (subtitulo != null)
                  Text(subtitulo, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            valor != null ? formatMoney(valor) : 'Por definir',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  String _tipoCobroLabel(TipoCobro tipo) => switch (tipo) {
    TipoCobro.parcial => 'Parcial',
    TipoCobro.plena => 'Plena',
    TipoCobro.nocturna => 'Nocturna',
  };
}
