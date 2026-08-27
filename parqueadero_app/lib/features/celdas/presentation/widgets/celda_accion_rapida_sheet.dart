import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/tipo_vehiculo.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/tipo_vehiculo_label.dart';
import '../../../../core/widgets/button_spinner.dart';
import '../../../../core/widgets/tiempo_transcurrido_text.dart';
import '../../../tickets/domain/pago.dart';
import '../../../tickets/presentation/cobro_preview_notifier.dart';
import '../../../tickets/presentation/cobro_preview_state.dart';
import '../../../tickets/presentation/salida_notifier.dart';
import '../../../tickets/presentation/salida_state.dart';
import '../../../tickets/presentation/ticket_abierto_de_celda_notifier.dart';
import '../../../tickets/presentation/ticket_detail_notifier.dart';
import '../../../tickets/presentation/ticket_list_notifier.dart';
import '../../../tickets/presentation/widgets/metodo_pago_label.dart';

/// Panel de acción rápida al tocar una celda OCUPADA (skill
/// `diseno-parqueadero`): busca el ticket abierto de la celda, muestra la
/// placa y el monto ya calculado por el backend (nunca uno propio) y deja
/// cobrar sin salir de la cuadrícula. Reutiliza los mismos cuatro notifiers
/// que ya existen para el flujo completo (`ticketAbiertoDeCeldaNotifier`,
/// `ticketDetailNotifier`, `cobroPreviewNotifier`, `salidaNotifier`) — nada
/// de lógica de tarifa ni de red nueva acá.
///
/// En pantallas ≥ [AppBreakpoints.mobile] (tablet/escritorio/web) se
/// presenta como un diálogo centrado con ancho máximo en vez de una barra
/// pegada abajo que se estiraría de borde a borde — mismo contenido, sin
/// handle de arrastre (no aplica en un diálogo flotante).
Future<void> showCeldaAccionRapida(BuildContext context, String celdaId) {
  final esAncho = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
  if (esAncho) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.asfalto,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
          child: CeldaAccionRapidaSheet(celdaId: celdaId, mostrarHandle: false),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.asfalto,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => CeldaAccionRapidaSheet(celdaId: celdaId),
  );
}

/// Handle bar del sheet: 36×4, radio 2 — la misma proporción que usa
/// Material por defecto para este afordance (`BottomSheetThemeData` no
/// expone un color por llamada, así que se dibuja a mano en vez de tocar el
/// tema global). No es un radio de contenido gobernado por `AppRadius`.
class _HandleBar extends StatelessWidget {
  const _HandleBar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.demarcacion.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class CeldaAccionRapidaSheet extends ConsumerStatefulWidget {
  const CeldaAccionRapidaSheet({super.key, required this.celdaId, this.mostrarHandle = true});

  final String celdaId;

  /// `false` cuando se presenta como diálogo centrado (pantallas anchas):
  /// un diálogo flotante no tiene el afordance de "arrastrar para cerrar"
  /// que sí tiene un bottom sheet.
  final bool mostrarHandle;

  @override
  ConsumerState<CeldaAccionRapidaSheet> createState() => _CeldaAccionRapidaSheetState();
}

class _CeldaAccionRapidaSheetState extends ConsumerState<CeldaAccionRapidaSheet> {
  bool _buscando = true;
  String? _ticketId;
  MetodoPago? _metodo;
  final _montoRecibidoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // `buscar()` escribe el estado de `TicketAbiertoDeCeldaNotifier`
    // (`isLoading: true`) de forma síncrona; llamarlo directo desde
    // `initState` viola la regla de Riverpod de no modificar un provider
    // mientras el árbol de widgets se está construyendo ("Tried to modify a
    // provider while the widget tree was building"). Mismo motivo por el
    // que `CeldaListNotifier.build()` difiere su primer `refrescar()` con
    // `Future.microtask` en vez de llamarlo directo.
    Future.microtask(_buscar);
  }

  Future<void> _buscar() async {
    final id = await ref.read(ticketAbiertoDeCeldaNotifierProvider(widget.celdaId).notifier).buscar();
    if (!mounted) return;
    setState(() {
      _buscando = false;
      _ticketId = id;
    });
  }

  @override
  void dispose() {
    _montoRecibidoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Observado sin condición (mismo criterio que `celda_detail_screen.dart`
    // con este mismo provider): si nadie lo mira mientras `buscar()` sigue
    // en vuelo, Riverpod desecha este `autoDispose` a mitad de camino y
    // `ref.mounted` se vuelve falso antes de que la búsqueda pueda leer la
    // respuesta real.
    final busquedaTicket = ref.watch(ticketAbiertoDeCeldaNotifierProvider(widget.celdaId));

    if (_buscando) {
      return _EstadoCentrado(
        handle: widget.mostrarHandle ? const _HandleBar() : null,
        child: const CircularProgressIndicator(color: AppColors.demarcacion),
      );
    }

    final ticketId = _ticketId;
    if (ticketId == null) {
      return _EstadoCentrado(
        handle: widget.mostrarHandle ? const _HandleBar() : null,
        child: Text(
          busquedaTicket.errorMessage ?? 'No se encontró un ticket abierto para esta celda.',
          style: const TextStyle(color: AppColors.demarcacion),
          textAlign: TextAlign.center,
        ),
      );
    }

    final detalle = ref.watch(ticketDetailNotifierProvider(ticketId));
    if (detalle.isLoading) {
      return _EstadoCentrado(
        handle: widget.mostrarHandle ? const _HandleBar() : null,
        child: const CircularProgressIndicator(color: AppColors.demarcacion),
      );
    }
    if (detalle.errorMessage != null) {
      return _EstadoCentrado(
        handle: widget.mostrarHandle ? const _HandleBar() : null,
        child: Text(
          detalle.errorMessage!,
          style: const TextStyle(color: AppColors.demarcacion),
          textAlign: TextAlign.center,
        ),
      );
    }

    final ticket = detalle.ticket!;
    final preview = ref.watch(cobroPreviewNotifierProvider(ticketId));
    final salida = ref.watch(salidaNotifierProvider(ticketId));
    final tipo = ticket.vehiculo?.tipo ?? TipoVehiculo.otro;
    // El preview de cobro nunca calcula un valor para tipo OTRO (lo digita
    // el operador) — el cobro de un tap no tiene dónde pedir ese valor, así
    // que acá el botón manda al formulario completo en vez de intentar
    // cobrar con un valor que la API rechazaría (422).
    final esOtro = tipo == TipoVehiculo.otro;

    final montoRecibido = int.tryParse(_montoRecibidoController.text.trim());
    final metodoEsEfectivo = _metodo == MetodoPago.efectivo;
    // `valorTotal` solo es null para tipo OTRO (ver doc de `CobroPreview`),
    // que ya está excluido de esta sección por `esOtro` — igual se maneja
    // acá porque el tipo estático sigue siendo `int?`.
    final totalEsperado = preview.preview?.valorTotal;
    final cambio = (montoRecibido != null && totalEsperado != null) ? montoRecibido - totalEsperado : null;
    final faltaMontoRecibido = metodoEsEfectivo && (cambio == null || cambio < 0);
    final enviando = salida.step == SalidaStep.enviando;

    Future<void> confirmar() async {
      if (esOtro) {
        Navigator.of(context).pop();
        context.push('/tickets/$ticketId/salida');
        return;
      }
      final ok = await ref.read(salidaNotifierProvider(ticketId).notifier).confirmarSalida(metodo: _metodo);
      if (ok && context.mounted) Navigator.of(context).pop();
    }

    void verHistorial() {
      final placa = ticket.vehiculo?.placa;
      if (placa != null) {
        ref.read(ticketListNotifierProvider.notifier).setPlacaFiltro(placa);
      }
      Navigator.of(context).pop();
      context.push('/tickets');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.mostrarHandle) const _HandleBar(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Celda ${ticket.celda?.codigo ?? '—'} · ${tipoVehiculoLabel(tipo)}',
                      style: const TextStyle(color: AppColors.demarcacion, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ticket.vehiculo?.placa ?? '—',
                      style: const TextStyle(color: AppColors.demarcacion, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Tiempo', style: TextStyle(color: AppColors.demarcacion, fontSize: 11)),
                  const SizedBox(height: 2),
                  TiempoTranscurridoText(
                    horaEntrada: ticket.horaEntrada,
                    style: const TextStyle(color: AppColors.demarcacion, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _TarjetaMonto(preview: preview),
          if (!esOtro) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final metodo in MetodoPago.values)
                  ChoiceChip(
                    label: Text(metodoPagoLabel(metodo)),
                    selected: _metodo == metodo,
                    onSelected: enviando ? null : (sel) => setState(() => _metodo = sel ? metodo : null),
                    backgroundColor: Colors.transparent,
                    selectedColor: AppColors.demarcacion,
                    side: const BorderSide(color: AppColors.demarcacion),
                    labelStyle: TextStyle(
                      color: _metodo == metodo ? AppColors.asfalto : AppColors.demarcacion,
                    ),
                  ),
              ],
            ),
            if (metodoEsEfectivo) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _montoRecibidoController,
                enabled: !enviando,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: AppColors.concreto),
                decoration: const InputDecoration(
                  labelText: 'Monto recibido',
                  labelStyle: TextStyle(color: AppColors.demarcacion),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.demarcacion)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.demarcacion, width: 2)),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (montoRecibido != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  cambio != null && cambio >= 0
                      ? 'Cambio a devolver: ${formatMoney(cambio)}'
                      : cambio != null
                      ? 'Faltan ${formatMoney(-cambio)} para cubrir el total'
                      : 'Calculando el total a cobrar...',
                  style: const TextStyle(color: AppColors.concreto),
                ),
              ],
            ],
          ],
          const SizedBox(height: AppSpacing.md),
          if (salida.error != null) ...[
            Text(
              salida.error!.message,
              style: const TextStyle(color: AppColors.demarcacion),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeSenal,
                foregroundColor: AppColors.concreto,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              onPressed: (enviando || preview.esTerminal || faltaMontoRecibido) ? null : confirmar,
              child: enviando
                  ? const ButtonSpinner()
                  : Text(esOtro ? 'Ir a registrar salida' : 'Registrar salida y cobrar'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.demarcacion,
                side: const BorderSide(color: AppColors.demarcacion),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
              ),
              onPressed: verHistorial,
              child: const Text('Ver historial'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoCentrado extends StatelessWidget {
  const _EstadoCentrado({this.handle, required this.child});

  final Widget? handle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (handle != null) ...[handle!, const SizedBox(height: AppSpacing.md)],
          Center(child: child),
        ],
      ),
    );
  }
}

/// "Total a cobrar": el monto viene siempre de `GET /tickets/:id/preview-cobro`
/// (mismo servicio que ya usa `RegistrarSalidaScreen`), nunca calculado acá.
class _TarjetaMonto extends StatelessWidget {
  const _TarjetaMonto({required this.preview});

  final CobroPreviewState preview;

  @override
  Widget build(BuildContext context) {
    final total = preview.preview?.valorTotal;
    Widget valor;
    if (total != null) {
      valor = Text(
        formatMoney(total),
        style: const TextStyle(color: AppColors.asfalto, fontSize: 20),
      );
    } else if (preview.preview != null) {
      // `valorTotal` null con preview ya cargado: tipo OTRO, sin valor
      // manual todavía. No debería llegar acá (esta tarjeta vive detrás de
      // `!esOtro`), pero se cubre para no mostrar un null crudo si algún
      // día cambia esa condición.
      valor = Text(
        'Se define al confirmar',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
      );
    } else if (preview.error != null) {
      valor = Text(
        preview.error!.message,
        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
        textAlign: TextAlign.end,
      );
    } else {
      valor = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: AppColors.concreto, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total a cobrar',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          Flexible(child: Align(alignment: Alignment.centerRight, child: valor)),
        ],
      ),
    );
  }
}
