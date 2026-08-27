import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/tipo_vehiculo_label.dart';
import '../../../core/utils/upper_case_text_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../celdas/domain/celda.dart';
import '../../celdas/presentation/celda_list_notifier.dart';
import '../../celdas/presentation/widgets/celda_estado_badge.dart';
import '../../turnos/presentation/widgets/turno_activo_indicator.dart';
import 'registrar_entrada_notifier.dart';

/// Único punto de entrada al flujo: se llega desde el tap en una celda LIBRE
/// de la cuadrícula (`celda_card.dart`), nunca con un selector propio de
/// celda. La celda llega por query param y ya debe estar cargada en
/// [celdaListNotifierProvider].
class RegistrarEntradaScreen extends ConsumerStatefulWidget {
  const RegistrarEntradaScreen({super.key, required this.celdaId});

  final String? celdaId;

  @override
  ConsumerState<RegistrarEntradaScreen> createState() => _RegistrarEntradaScreenState();
}

class _RegistrarEntradaScreenState extends ConsumerState<RegistrarEntradaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _propietarioNombreController = TextEditingController();
  final _propietarioTelefonoController = TextEditingController();
  TipoVehiculo? _tipoVehiculo;
  bool _tipoInicializado = false;

  @override
  void dispose() {
    _placaController.dispose();
    _propietarioNombreController.dispose();
    _propietarioTelefonoController.dispose();
    super.dispose();
  }

  Future<void> _submit(Celda celda) async {
    if (!_formKey.currentState!.validate()) return;
    final ticket = await ref
        .read(registrarEntradaNotifierProvider.notifier)
        .registrar(
          placa: _placaController.text.trim().toUpperCase(),
          tipoVehiculo: _tipoVehiculo!,
          celdaId: celda.id,
          propietarioNombre: _propietarioNombreController.text.trim(),
          propietarioTelefono: _propietarioTelefonoController.text.trim(),
        );
    if (ticket == null || !mounted) return;

    // Sin diálogo de "Aceptar": esta pantalla se repite decenas de veces por
    // turno y no es una acción irreversible que necesite doble confirmación
    // (a diferencia de registrar salida o cerrar turno). Vuelve a la
    // cuadrícula de inmediato y confirma con un snackbar que no exige toque
    // — mismo idioma que ya usa celda_quick_actions_sheet.dart (pop seguido
    // de ScaffoldMessenger.of(context), seguro acá porque la app tiene un
    // único ScaffoldMessenger raíz en MaterialApp.router).
    context.pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Entrada registrada · Ticket ${ticket.codigo}')));
  }

  @override
  Widget build(BuildContext context) {
    final celdaId = widget.celdaId;
    // Esta pantalla nunca necesita la lista completa ni los filtros de
    // `CeldaListState` (eso es de `CeldasScreen`): solo la celda puntual que
    // llegó por query param, más `isLoading`/`errorMessage` para la rama
    // "no encontrada todavía". `.select()` con un record compara por valor
    // (Celda ya implementa `==`), así que el poll de 30s de
    // `CeldaListNotifier` deja de reconstruir este formulario completo
    // cuando ninguno de esos tres campos cambió de verdad.
    final celdaState = ref.watch(
      celdaListNotifierProvider.select((s) {
        Celda? celda;
        if (celdaId != null) {
          for (final c in s.celdas) {
            if (c.id == celdaId) {
              celda = c;
              break;
            }
          }
        }
        return (celda: celda, isLoading: s.isLoading, errorMessage: s.errorMessage);
      }),
    );
    final celda = celdaState.celda;

    if (celda == null) {
      Widget body;
      if (celdaState.isLoading) {
        body = const Center(child: CircularProgressIndicator());
      } else if (celdaState.errorMessage != null) {
        body = ErrorState(
          message: celdaState.errorMessage!,
          onRetry: ref.read(celdaListNotifierProvider.notifier).refrescar,
        );
      } else {
        body = const EmptyState(
          icon: Icons.error_outline,
          message: 'No se encontró la celda seleccionada. Vuelve a la cuadrícula e inténtalo de nuevo.',
        );
      }
      return Scaffold(appBar: AppBar(title: const Text('Registrar entrada')), body: body);
    }

    if (!_tipoInicializado) {
      _tipoVehiculo = celda.tipoPermitido;
      _tipoInicializado = true;
    }

    final state = ref.watch(registrarEntradaNotifierProvider);
    final celdaSeleccionada = celda;

    return Scaffold(
      appBar: AppBar(title: Text('Registrar entrada · ${celdaSeleccionada.codigo}')),
      body: Column(
        children: [
          const TurnoActivoIndicator(),
          Expanded(
            child: SafeArea(
              bottom: false,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Hero(
                                    tag: 'celda-estado-${celdaSeleccionada.id}',
                                    child: const CeldaEstadoBadge(estado: EstadoCelda.libre, size: 32),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Celda ${celdaSeleccionada.codigo}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text('Zona ${celdaSeleccionada.zona}'),
                              Text('Tipo permitido: ${tipoVehiculoLabel(celdaSeleccionada.tipoPermitido)}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _placaController,
                        enabled: !state.isLoading,
                        autofocus: true,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          UpperCaseTextFormatter(),
                        ],
                        decoration: const InputDecoration(labelText: 'Placa'),
                        validator: placaValidator,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _TipoVehiculoDropdown(
                        initialValue: _tipoVehiculo!,
                        enabled: !state.isLoading,
                        // Sin setState acá: el valor solo lo necesita
                        // _submit() más adelante (async, on-tap), no ningún
                        // otro widget de este build(). Guardarlo en un campo
                        // plano evita reconstruir las ~150 líneas del
                        // formulario por cada selección.
                        onChanged: (value) => _tipoVehiculo = value,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _propietarioNombreController,
                        enabled: !state.isLoading,
                        decoration: const InputDecoration(labelText: 'Nombre del propietario (opcional)'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _propietarioTelefonoController,
                        enabled: !state.isLoading,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Teléfono del propietario (opcional)'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Botón (y error) fuera del scroll, siempre visible: con el teclado
      // abierto, el formulario de 4 campos podía empujar "Registrar entrada"
      // fuera del viewport y obligar a cerrar el teclado o hacer scroll de
      // más para confirmar — justo en la tarea que más se repite en el turno.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.errorMessage != null) ...[
                Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              ElevatedButton(
                onPressed: state.isLoading ? null : () => _submit(celdaSeleccionada),
                child: state.isLoading ? const ButtonSpinner() : const Text('Registrar entrada'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aislado del formulario para que elegir un tipo no reconstruya las ~150
/// líneas de `RegistrarEntradaScreen` — el valor elegido solo lo lee
/// `_submit()` más adelante (vía [onChanged]), ningún otro widget del
/// formulario depende de él en cada tecla/selección.
class _TipoVehiculoDropdown extends StatefulWidget {
  const _TipoVehiculoDropdown({required this.initialValue, required this.enabled, required this.onChanged});

  final TipoVehiculo initialValue;
  final bool enabled;
  final ValueChanged<TipoVehiculo> onChanged;

  @override
  State<_TipoVehiculoDropdown> createState() => _TipoVehiculoDropdownState();
}

class _TipoVehiculoDropdownState extends State<_TipoVehiculoDropdown> {
  late TipoVehiculo _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TipoVehiculo>(
      initialValue: _value,
      decoration: const InputDecoration(labelText: 'Tipo de vehículo'),
      items: [
        for (final tipo in TipoVehiculo.values)
          DropdownMenuItem(value: tipo, child: Text(tipoVehiculoLabel(tipo))),
      ],
      onChanged: widget.enabled
          ? (value) {
              if (value == null) return;
              setState(() => _value = value);
              widget.onChanged(value);
            }
          : null,
    );
  }
}
