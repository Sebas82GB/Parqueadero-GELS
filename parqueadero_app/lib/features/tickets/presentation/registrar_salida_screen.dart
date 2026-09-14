import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/tipo_vehiculo.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/bogota_time.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/print/print_launcher.dart';
import '../../../core/utils/tipo_vehiculo_label.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/detail_skeleton.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/tiempo_transcurrido_text.dart';
import '../../turnos/presentation/widgets/turno_activo_indicator.dart';
import '../domain/pago.dart';
import '../domain/ticket.dart';
import 'cobro_preview_notifier.dart';
import 'cobro_preview_state.dart';
import 'salida_notifier.dart';
import 'salida_state.dart';
import 'ticket_detail_notifier.dart';
import 'widgets/desglose_view.dart';
import 'widgets/metodo_pago_label.dart';
import 'widgets/recibo_view.dart';

/// `registrarSalida` sigue calculando el cobro y cerrando el ticket en la
/// misma llamada (transaccional, ver CLAUDE.md del backend), pero ahora hay
/// una vista previa de solo lectura (`GET /tickets/:id/preview-cobro`, vía
/// [cobroPreviewNotifierProvider]) que se refresca sola cada 30s mientras el
/// operador llena el formulario, así que el diálogo de confirmación puede
/// mostrar el monto exacto ANTES de cerrar el ticket. El flujo es: (1)
/// formulario con lo que el operador ya sabe + el preview en vivo, (2)
/// diálogo "¿confirmar?" con el monto que muestra el preview, (3) la llamada
/// real a `registrarSalida`, (4) si tiene éxito, el recibo con el desglose
/// ya calculado (puede diferir en unos pesos del último preview si pasó
/// tiempo entre el diálogo y la confirmación); si falla con 422 (falta
/// metodo/valorManual) se reintenta desde el mismo formulario, y si falla
/// con 409 OPERADOR_SIN_TURNO_ABIERTO se ofrece abrir turno sin salir del
/// flujo.
class RegistrarSalidaScreen extends ConsumerStatefulWidget {
  const RegistrarSalidaScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<RegistrarSalidaScreen> createState() => _RegistrarSalidaScreenState();
}

class _RegistrarSalidaScreenState extends ConsumerState<RegistrarSalidaScreen> {
  final _valorManualController = TextEditingController();
  final _montoRecibidoController = TextEditingController();
  MetodoPago? _metodo;

  @override
  void dispose() {
    _valorManualController.dispose();
    _montoRecibidoController.dispose();
    super.dispose();
  }

  Future<void> _confirmarYRegistrar() async {
    final texto = _valorManualController.text.trim();
    final valorManual = texto.isEmpty ? null : int.tryParse(texto);

    // El monto exacto viene del último preview conocido; para vehículos
    // OTRO el preview nunca calcula un valor (lo digita el operador), así
    // que ahí se muestra lo que el operador ya escribió en el formulario.
    final previewValor = ref.read(cobroPreviewNotifierProvider(widget.ticketId)).preview?.valorTotal;
    final total = valorManual ?? previewValor;
    final montoTexto = total != null ? formatMoney(total) : 'el valor calculado por el sistema';

    // El cambio nunca viaja al backend ni se persiste: es aritmética de
    // presentación sobre un total que el backend ya calculó, igual que la
    // diferencia de caja en `TurnoCierreScreen`.
    final montoRecibido = int.tryParse(_montoRecibidoController.text.trim());
    final cambioTexto = (_metodo == MetodoPago.efectivo && montoRecibido != null && total != null)
        ? ' Recibe ${formatMoney(montoRecibido)} y debe dar ${formatMoney(montoRecibido - total)} de cambio.'
        : '';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Confirmar salida?'),
        content: Text(
          'El ticket se cerrará con un cobro de $montoTexto.$cambioTexto Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    await ref
        .read(salidaNotifierProvider(widget.ticketId).notifier)
        .confirmarSalida(metodo: _metodo, valorManual: valorManual);
  }

  @override
  Widget build(BuildContext context) {
    final salida = ref.watch(salidaNotifierProvider(widget.ticketId));

    if (salida.step == SalidaStep.exito) {
      final montoRecibido = int.tryParse(_montoRecibidoController.text.trim());
      return _ReciboSalida(ticket: salida.ticketCerrado!, montoRecibido: montoRecibido);
    }

    final detalle = ref.watch(ticketDetailNotifierProvider(widget.ticketId));

    if (detalle.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registrar salida')),
        body: const DetailSkeleton(lineas: 5),
      );
    }
    if (detalle.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registrar salida')),
        body: ErrorState(
          message: detalle.errorMessage!,
          onRetry: ref.read(ticketDetailNotifierProvider(widget.ticketId).notifier).cargar,
        ),
      );
    }

    final ticket = detalle.ticket!;
    final esOtro = ticket.vehiculo?.tipo == TipoVehiculo.otro;
    final enviando = salida.step == SalidaStep.enviando;
    final preview = ref.watch(cobroPreviewNotifierProvider(widget.ticketId));

    final valorManualTexto = _valorManualController.text.trim();
    final valorManual = valorManualTexto.isEmpty ? null : int.tryParse(valorManualTexto);
    final totalEsperado = valorManual ?? preview.preview?.valorTotal;
    final metodoEsEfectivo = _metodo == MetodoPago.efectivo;
    final montoRecibido = int.tryParse(_montoRecibidoController.text.trim());
    final cambio = (montoRecibido != null && totalEsperado != null) ? montoRecibido - totalEsperado : null;
    final faltaMontoRecibido = metodoEsEfectivo && (cambio == null || cambio < 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar salida')),
      body: Column(
        children: [
          const TurnoActivoIndicator(),
          Expanded(
            child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Placa ${ticket.vehiculo?.placa ?? '—'}', style: Theme.of(context).textTheme.titleMedium),
                      if (ticket.vehiculo != null) Text('Tipo: ${tipoVehiculoLabel(ticket.vehiculo!.tipo)}'),
                      Text('Celda: ${ticket.celda?.codigo ?? '—'}'),
                      Text('Entrada: ${formatBogota(ticket.horaEntrada)}'),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Text('Tiempo transcurrido: ', style: Theme.of(context).textTheme.titleMedium),
                          TiempoTranscurridoText(
                            horaEntrada: ticket.horaEntrada,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _PreviewCobroSection(preview: preview),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<MetodoPago?>(
                initialValue: _metodo,
                decoration: const InputDecoration(labelText: 'Método de pago'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sin especificar')),
                  for (final metodo in MetodoPago.values)
                    DropdownMenuItem(value: metodo, child: Text(metodoPagoLabel(metodo))),
                ],
                onChanged: enviando ? null : (value) => setState(() => _metodo = value),
              ),
              if (esOtro) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _valorManualController,
                  enabled: !enviando,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Valor a cobrar (vehículo tipo Otro)'),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              if (metodoEsEfectivo) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _montoRecibidoController,
                  enabled: !enviando,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Monto recibido'),
                  onChanged: (_) => setState(() {}),
                ),
                if (montoRecibido != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    cambio != null && cambio >= 0
                        ? 'Cambio a devolver: ${formatMoney(cambio)}'
                        : cambio != null
                        ? 'Faltan ${formatMoney(-cambio)} para cubrir el total'
                        : 'Calculando el total a cobrar...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ],
              if (salida.error != null) ...[
                const SizedBox(height: AppSpacing.md),
                ErrorBanner(error: salida.error!),
                if (salida.error case ApiException(code: 'OPERADOR_SIN_TURNO_ABIERTO')) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => context.push('/turnos/abrir'),
                    child: const Text('Abrir turno'),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: (enviando || preview.esTerminal || faltaMontoRecibido) ? null : _confirmarYRegistrar,
                child: enviando ? const ButtonSpinner() : const Text('Registrar salida'),
              ),
            ],
          ),
        ),
      ),
          ),
        ],
      ),
    );
  }

}

/// Vista previa en vivo de `GET /tickets/:id/preview-cobro`. Reutiliza
/// [DesgloseView] tal cual — ya distingue bloques/mensualidad/manual con
/// títulos claros, así que el preview y el recibo final se ven consistentes.
class _PreviewCobroSection extends StatelessWidget {
  const _PreviewCobroSection({required this.preview});

  final CobroPreviewState preview;

  @override
  Widget build(BuildContext context) {
    if (preview.esTerminal) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ErrorBanner(error: preview.error!),
        ),
      );
    }

    final datos = preview.preview;
    if (datos == null) {
      if (preview.error != null) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ErrorBanner(error: preview.error!),
          ),
        );
      }
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LoadingSkeleton(height: 20),
              SizedBox(height: AppSpacing.sm),
              LoadingSkeleton(height: 20),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Vista previa del cobro', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            DesgloseView(desglose: datos.desglose, valorTotal: datos.valorTotal),
            const SizedBox(height: AppSpacing.xs),
            Text(
              preview.error != null
                  ? 'No se pudo actualizar; mostrando el último cálculo (${formatBogota(datos.horaSalida, 'h:mm:ss a')}).'
                  : 'Actualizado a las ${formatBogota(datos.horaSalida, 'h:mm:ss a')}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReciboSalida extends StatelessWidget {
  const _ReciboSalida({required this.ticket, this.montoRecibido});

  final Ticket ticket;

  /// Lo que el operador escribió en "Monto recibido" antes de confirmar.
  /// Solo existe en memoria de esta pantalla: no viaja al backend ni se
  /// imprime en la tirilla (`ReciboView`), que es un documento fiscal y solo
  /// muestra lo que la API calculó.
  final int? montoRecibido;

  @override
  Widget build(BuildContext context) {
    // El checkout ya cerró el ticket (tiene horaSalida), así que el backend
    // siempre devuelve `recibo` en esta respuesta — nunca null acá.
    final recibo = ticket.recibo!;
    final esEfectivo = recibo.metodoPago == MetodoPago.efectivo;
    return Scaffold(
      appBar: AppBar(title: const Text('Salida registrada')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cerrado el ${formatBogota(recibo.horaSalida)}'),
                        if (esEfectivo && montoRecibido != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text('Recibido: ${formatMoney(montoRecibido!)}'),
                          Text(
                            'Cambio a devolver: ${formatMoney(montoRecibido! - recibo.total)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ReciboView(recibo: recibo),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: triggerBrowserPrint,
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir'),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(onPressed: () => context.go('/celdas'), child: const Text('Volver a celdas')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
