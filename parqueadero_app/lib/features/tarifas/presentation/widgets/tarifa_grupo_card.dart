import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/status_style.dart';
import '../../../../core/utils/bogota_time.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/tipo_vehiculo_label.dart';
import '../../../../core/widgets/button_spinner.dart';
import '../../domain/tarifa.dart';
import '../tarifa_accion_notifier.dart';

/// Una tarjeta por tipo de vehículo: la fila vigente resaltada (si la hay)
/// con acción de cerrarla, y el resto colapsado en un histórico.
class TarifaGrupoCard extends ConsumerWidget {
  const TarifaGrupoCard({super.key, required this.tipo, required this.tarifas});

  final TipoVehiculo tipo;

  /// Ya viene ordenada por `vigenteDesde` descendente (ver
  /// `TarifaListState.tarifasFiltradasPorTipo`).
  final List<Tarifa> tarifas;

  Future<void> _confirmarCerrar(BuildContext context, WidgetRef ref, Tarifa vigente) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar vigencia?'),
        content: Text(
          'La tarifa de ${tipoVehiculoLabel(tipo)} vigente desde ${formatBogota(vigente.vigenteDesde, 'd MMM y')} '
          'dejará de aplicar de inmediato y no se reemplaza por otra. '
          'Los vehículos de este tipo no podrán registrar entrada hasta que crees una nueva. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmado != true) return;
    // TarifaAccionNotifier.cerrar() ya refresca tarifaListNotifierProvider
    // por sí solo en caso de éxito.
    await ref.read(tarifaAccionNotifierProvider(vigente.id).notifier).cerrar();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Tarifa? vigente;
    for (final t in tarifas) {
      if (t.esVigente()) {
        vigente = t;
        break;
      }
    }
    final historico = [for (final t in tarifas) if (t.id != vigente?.id) t];
    final accion = vigente == null ? null : ref.watch(tarifaAccionNotifierProvider(vigente.id));
    final success = StatusStyle.of(StatusTone.success).color;
    final warning = StatusStyle.of(StatusTone.warning).color;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tipoVehiculoLabel(tipo), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (vigente != null) ...[
              Row(
                children: [
                  Chip(
                    label: const Text('Vigente'),
                    backgroundColor: success.withValues(alpha: 0.12),
                    side: BorderSide(color: success),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Desde ${formatBogota(vigente.vigenteDesde, 'd MMM y')}'),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Minuto: ${formatMoney(vigente.valorMinuto)} · Plena: ${formatMoney(vigente.valorPlena)}'),
              Text('Nocturna: ${formatMoney(vigente.valorNocturna)} · Mes: ${formatMoney(vigente.valorMes)}'),
              if (accion?.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(accion!.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: accion!.isLoading ? null : () => _confirmarCerrar(context, ref, vigente!),
                child: accion.isLoading ? const ButtonSpinner(size: 20) : const Text('Cerrar vigencia'),
              ),
            ] else
              Text(
                'Sin tarifa vigente — los vehículos tipo ${tipoVehiculoLabel(tipo)} no podrán registrar '
                'entrada hasta crear una nueva.',
                style: TextStyle(color: warning),
              ),
            if (historico.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Ver histórico (${historico.length})'),
                children: [for (final t in historico) _HistoricoRow(tarifa: t)],
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoricoRow extends StatelessWidget {
  const _HistoricoRow({required this.tarifa});

  final Tarifa tarifa;

  @override
  Widget build(BuildContext context) {
    final rango = tarifa.vigenteHasta == null
        ? 'Desde ${formatBogota(tarifa.vigenteDesde, 'd MMM y')}'
        : '${formatBogota(tarifa.vigenteDesde, 'd MMM y')} – ${formatBogota(tarifa.vigenteHasta!, 'd MMM y')}';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(rango),
      subtitle: Text(
        'Minuto: ${formatMoney(tarifa.valorMinuto)} · Plena: ${formatMoney(tarifa.valorPlena)} · '
        'Nocturna: ${formatMoney(tarifa.valorNocturna)} · Mes: ${formatMoney(tarifa.valorMes)}',
      ),
    );
  }
}
