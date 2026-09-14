import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/detail_skeleton.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/error_state.dart';
import '../domain/turno.dart';
import 'turno_cierre_notifier.dart';
import 'turno_cierre_state.dart';
import 'turno_detail_notifier.dart';
import 'widgets/arqueo_summary_view.dart';
import 'widgets/diferencia_texto.dart';

/// Muestra el esperado (arqueo en vivo del propio turno, vía
/// `turnoDetailNotifierProvider`), pide el efectivo contado, recalcula la
/// diferencia en vivo mientras se escribe (aritmética de presentación sobre
/// un número que ya entregó el backend, no una regla de negocio nueva) y, al
/// confirmar, cierra el turno o completa su arqueo pendiente — mismo
/// formulario para las dos acciones, distinguidas por el `estado` del turno
/// que ya está cargado. Como el backend devuelve el arqueo completo en la
/// misma respuesta, el resultado final se muestra sin pedir otra llamada —
/// mismo espíritu que `_ReciboSalida` en el flujo de salida.
class TurnoCierreScreen extends ConsumerStatefulWidget {
  const TurnoCierreScreen({super.key, required this.turnoId});

  final String turnoId;

  @override
  ConsumerState<TurnoCierreScreen> createState() => _TurnoCierreScreenState();
}

class _TurnoCierreScreenState extends ConsumerState<TurnoCierreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contadoController = TextEditingController();

  /// Capturado al confirmar, no recalculado después: una vez la acción tiene
  /// éxito el turno ya quedó `CERRADO` en los dos casos, así que no hay forma
  /// de distinguirlos leyendo el resultado — solo recordando cuál se pidió.
  bool _completandoArqueo = false;

  @override
  void dispose() {
    _contadoController.dispose();
    super.dispose();
  }

  String? _contadoValidator(String? value) {
    final requeridoOEntero = requiredIntegerValidator(value);
    if (requeridoOEntero != null) return requeridoOEntero;
    if (int.parse(value!.trim()) < 0) return 'Ingresa un valor válido';
    return null;
  }

  Future<void> _confirmarYCerrar(int esperado, {required bool esCompletarArqueo}) async {
    if (!_formKey.currentState!.validate()) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(esCompletarArqueo ? '¿Completar arqueo?' : '¿Cerrar turno?'),
        content: Text(
          esCompletarArqueo
              ? 'Se registrará el efectivo contado y la diferencia contra lo esperado, y el turno '
                    'quedará cerrado. Esta acción no se puede deshacer.'
              : 'Se registrará el efectivo contado y la diferencia contra lo esperado. '
                    'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    _completandoArqueo = esCompletarArqueo;
    final contado = int.parse(_contadoController.text.trim());
    final notifier = ref.read(turnoCierreNotifierProvider(widget.turnoId).notifier);
    if (esCompletarArqueo) {
      await notifier.completarArqueo(contado);
    } else {
      await notifier.cerrar(contado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cierre = ref.watch(turnoCierreNotifierProvider(widget.turnoId));

    if (cierre.step == TurnoCierreStep.exito) {
      return Scaffold(
        appBar: AppBar(title: Text(_completandoArqueo ? 'Arqueo completado' : 'Turno cerrado')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ArqueoSummaryView(arqueo: cierre.resultado!),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => context.go('/celdas'),
                  child: const Text('Volver a celdas'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final detalle = ref.watch(turnoDetailNotifierProvider(widget.turnoId));

    if (detalle.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cerrar turno')),
        body: const DetailSkeleton(),
      );
    }
    if (detalle.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cerrar turno')),
        body: ErrorState(
          message: detalle.errorMessage!,
          onRetry: ref.read(turnoDetailNotifierProvider(widget.turnoId).notifier).cargar,
        ),
      );
    }

    final esperado = detalle.arqueo!.efectivoEsperado;
    final esCompletarArqueo = detalle.arqueo!.estado == EstadoTurno.cerradoPendienteArqueo;
    final enviando = cierre.step == TurnoCierreStep.enviando;
    final contado = int.tryParse(_contadoController.text.trim());
    final tituloAccion = esCompletarArqueo ? 'Completar arqueo' : 'Cerrar turno';

    return Scaffold(
      appBar: AppBar(title: Text(tituloAccion)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text('Efectivo esperado: ${formatMoney(esperado)}'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _contadoController,
                  enabled: !enviando,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Efectivo contado'),
                  validator: _contadoValidator,
                  onChanged: (_) => setState(() {}),
                ),
                if (contado != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(diferenciaTexto(contado - esperado)),
                ],
                if (cierre.error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  ErrorBanner(error: cierre.error!),
                ],
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: enviando
                      ? null
                      : () => _confirmarYCerrar(esperado, esCompletarArqueo: esCompletarArqueo),
                  child: enviando ? const ButtonSpinner() : Text(tituloAccion),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
