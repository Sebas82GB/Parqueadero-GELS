import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/bogota_time.dart';
import '../../../core/utils/elapsed_time.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/upper_case_text_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import '../domain/ticket.dart';
import 'buscar_placa_notifier.dart';
import 'widgets/ticket_estado_chip.dart';

/// Responde "¿está adentro?" en la misma pantalla: no salta a un formulario
/// de cobro. Busca sin fijar `estado` (ver `buscar_placa_notifier.dart`), así
/// que también encuentra tickets ya cerrados y distingue "nunca entró"
/// (sin resultados) de "ya salió" (encontrado, no abierto). "Registrar
/// salida" queda como acción secundaria, visible solo para OPERADOR — un
/// ADMIN puede consultar la placa pero esa acción es 403 para su rol.
class BuscarPlacaScreen extends ConsumerStatefulWidget {
  const BuscarPlacaScreen({super.key});

  @override
  ConsumerState<BuscarPlacaScreen> createState() => _BuscarPlacaScreenState();
}

class _BuscarPlacaScreenState extends ConsumerState<BuscarPlacaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Solo refresca el tiempo transcurrido mostrado para un ticket todavía
    // abierto — estado de UI puro, no vuelve a pedir nada a la red. Mismo
    // criterio que `registrar_salida_screen.dart`.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _placaController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(buscarPlacaNotifierProvider.notifier).buscar(_placaController.text.trim().toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(buscarPlacaNotifierProvider);
    final esOperador = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.operador;

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar por placa')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _placaController,
                      enabled: !state.isLoading,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [UpperCaseTextFormatter()],
                      decoration: const InputDecoration(labelText: 'Placa'),
                      validator: placaValidator,
                      onFieldSubmitted: (_) => _buscar(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: state.isLoading ? null : _buscar,
                      child: state.isLoading ? const ButtonSpinner() : const Text('Buscar'),
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ] else if (state.buscado) ...[
                      const SizedBox(height: AppSpacing.lg),
                      state.ticket == null
                          ? const Text(
                              'No hay registros de esta placa en el parqueadero.',
                              textAlign: TextAlign.center,
                            )
                          : _ResultadoTicket(ticket: state.ticket!, esOperador: esOperador),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultadoTicket extends StatelessWidget {
  const _ResultadoTicket({required this.ticket, required this.esOperador});

  final Ticket ticket;
  final bool esOperador;

  @override
  Widget build(BuildContext context) {
    final adentro = ticket.estado == EstadoTicket.abierto;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Placa ${ticket.vehiculo?.placa ?? '—'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TicketEstadoChip(estado: ticket.estado),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Celda: ${ticket.celda?.codigo ?? '—'}'),
            Text('Entrada: ${formatBogota(ticket.horaEntrada)}'),
            if (adentro) ...[
              Text(
                'Tiempo transcurrido: '
                '${formatElapsed(DateTime.now().toUtc().difference(ticket.horaEntrada))}',
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text('Cobro: se calcula al registrar la salida.'),
              if (esOperador) ...[
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => context.push('/tickets/${ticket.id}/salida'),
                  child: const Text('Registrar salida'),
                ),
              ],
            ] else ...[
              Text('Salida: ${ticket.horaSalida != null ? formatBogota(ticket.horaSalida!) : '—'}'),
              if (ticket.valorTotal != null) Text('Cobrado: ${formatMoney(ticket.valorTotal!)}'),
              if (ticket.recibo != null) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => context.push('/tickets/${ticket.id}/recibo'),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Ver recibo'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
