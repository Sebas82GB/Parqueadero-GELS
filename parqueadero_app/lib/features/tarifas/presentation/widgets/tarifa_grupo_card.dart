import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/status_style.dart';
import '../../../../core/utils/bogota_time.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/tipo_vehiculo_label.dart';
import '../../../../core/utils/validators.dart';
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

  Future<void> _editar(BuildContext context, WidgetRef ref, Tarifa vigente) async {
    final cambios = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _EditarTarifaDialog(tarifa: vigente),
    );
    // Diálogo cancelado, o sin cambios (el propio diálogo ya evita llamar al
    // backend con un body vacío, que el validador `.strict()` rechaza).
    if (cambios == null || cambios.isEmpty) return;
    // TarifaAccionNotifier.actualizar() ya refresca tarifaListNotifierProvider
    // por sí solo en caso de éxito.
    await ref
        .read(tarifaAccionNotifierProvider(vigente.id).notifier)
        .actualizar(
          valorMinuto: cambios['valorMinuto'],
          valorPlena: cambios['valorPlena'],
          valorNocturna: cambios['valorNocturna'],
          valorMes: cambios['valorMes'],
        );
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: accion!.isLoading ? null : () => _editar(context, ref, vigente!),
                      child: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: accion.isLoading ? null : () => _confirmarCerrar(context, ref, vigente!),
                      child: accion.isLoading ? const ButtonSpinner(size: 20) : const Text('Cerrar vigencia'),
                    ),
                  ),
                ],
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

/// Diálogo de edición de la tarifa vigente. Devuelve un `Map` con solo los
/// campos que cambiaron respecto a [tarifa] (vacío si no cambió ninguno):
/// el llamador decide, con ese resultado, si vale la pena llamar al
/// backend — que rechaza con 400 un body vacío.
class _EditarTarifaDialog extends StatefulWidget {
  const _EditarTarifaDialog({required this.tarifa});

  final Tarifa tarifa;

  @override
  State<_EditarTarifaDialog> createState() => _EditarTarifaDialogState();
}

class _EditarTarifaDialogState extends State<_EditarTarifaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _valorMinutoController = TextEditingController(text: widget.tarifa.valorMinuto.toString());
  late final _valorPlenaController = TextEditingController(text: widget.tarifa.valorPlena.toString());
  late final _valorNocturnaController = TextEditingController(text: widget.tarifa.valorNocturna.toString());
  late final _valorMesController = TextEditingController(text: widget.tarifa.valorMes.toString());

  @override
  void dispose() {
    _valorMinutoController.dispose();
    _valorPlenaController.dispose();
    _valorNocturnaController.dispose();
    _valorMesController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final valorMinuto = int.parse(_valorMinutoController.text.trim());
    final valorPlena = int.parse(_valorPlenaController.text.trim());
    final valorNocturna = int.parse(_valorNocturnaController.text.trim());
    final valorMes = int.parse(_valorMesController.text.trim());
    final cambios = <String, int>{
      if (valorMinuto != widget.tarifa.valorMinuto) 'valorMinuto': valorMinuto,
      if (valorPlena != widget.tarifa.valorPlena) 'valorPlena': valorPlena,
      if (valorNocturna != widget.tarifa.valorNocturna) 'valorNocturna': valorNocturna,
      if (valorMes != widget.tarifa.valorMes) 'valorMes': valorMes,
    };
    Navigator.of(context).pop(cambios);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarifa'),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _valorMinutoController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Valor por minuto'),
                validator: requiredIntegerValidator,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _valorPlenaController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Valor tarifa plena'),
                validator: requiredIntegerValidator,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _valorNocturnaController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Valor tarifa nocturna'),
                validator: requiredIntegerValidator,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _valorMesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Valor mensualidad'),
                validator: requiredIntegerValidator,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
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
