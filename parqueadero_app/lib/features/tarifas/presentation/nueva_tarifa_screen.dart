import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/status_style.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/tipo_vehiculo_label.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/acceso_restringido.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import '../domain/tarifa.dart';
import 'nueva_tarifa_notifier.dart';
import 'tarifa_simulacion_notifier.dart';
import 'tarifa_simulacion_state.dart';

/// Duraciones de ejemplo para la vista previa: cubren una fracción parcial,
/// una plena exacta, dos bloques y un cruce de medianoche/nocturna — el
/// mismo rango de casos que documenta la tabla de referencia del backend.
const _duracionesPreset = {
  30: '30 min',
  60: '1 hora',
  120: '2 horas',
  360: '6 horas',
  720: '12 horas',
  1440: '1 día',
};

class NuevaTarifaScreen extends ConsumerStatefulWidget {
  const NuevaTarifaScreen({super.key});

  @override
  ConsumerState<NuevaTarifaScreen> createState() => _NuevaTarifaScreenState();
}

class _NuevaTarifaScreenState extends ConsumerState<NuevaTarifaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorMinutoController = TextEditingController();
  final _valorPlenaController = TextEditingController();
  final _valorNocturnaController = TextEditingController();
  final _valorMesController = TextEditingController();
  TipoVehiculo? _tipoVehiculo;
  int _duracionMinutos = 120;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _valorMinutoController,
      _valorPlenaController,
      _valorNocturnaController,
      _valorMesController,
    ]) {
      controller.addListener(_onCamposCambiaron);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _valorMinutoController.dispose();
    _valorPlenaController.dispose();
    _valorNocturnaController.dispose();
    _valorMesController.dispose();
    super.dispose();
  }

  // El preview no es un requisito para crear la tarifa, solo una ayuda: no
  // tiene sentido recalcularlo en cada tecla, así que se espera una pausa
  // corta. `valorMes` no participa (no afecta el cobro por estadía, solo la
  // mensualidad), así que no dispara recálculo.
  void _onCamposCambiaron() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _simular);
  }

  void _simular() {
    final tipoVehiculo = _tipoVehiculo;
    final valorMinuto = int.tryParse(_valorMinutoController.text.trim());
    final valorPlena = int.tryParse(_valorPlenaController.text.trim());
    final valorNocturna = int.tryParse(_valorNocturnaController.text.trim());
    if (tipoVehiculo == null || valorMinuto == null || valorPlena == null || valorNocturna == null) {
      ref.read(tarifaSimulacionNotifierProvider.notifier).limpiar();
      return;
    }

    ref
        .read(tarifaSimulacionNotifierProvider.notifier)
        .simular(
          tipoVehiculo: tipoVehiculo,
          valorMinuto: valorMinuto,
          valorPlena: valorPlena,
          valorNocturna: valorNocturna,
          duracionMinutos: _duracionMinutos,
        );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _tipoVehiculo == null) {
      if (_tipoVehiculo == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Selecciona un tipo de vehículo.')));
      }
      return;
    }

    final tarifa = await ref
        .read(nuevaTarifaNotifierProvider.notifier)
        .crear(
          tipoVehiculo: _tipoVehiculo!,
          valorMinuto: int.parse(_valorMinutoController.text.trim()),
          valorPlena: int.parse(_valorPlenaController.text.trim()),
          valorNocturna: int.parse(_valorNocturnaController.text.trim()),
          valorMes: int.parse(_valorMesController.text.trim()),
        );
    if (tarifa == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tarifa creada'),
        content: Text(
          'Nueva tarifa vigente para ${tipoVehiculoLabel(tarifa.tipoVehiculo)}. '
          'La vigencia anterior de este tipo, si existía, quedó cerrada.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Aceptar')),
        ],
      ),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.admin;
    if (!esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nueva tarifa')),
        body: const AccesoRestringido(),
      );
    }

    final state = ref.watch(nuevaTarifaNotifierProvider);
    final warning = StatusStyle.of(StatusTone.warning).color;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva tarifa')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  decoration: BoxDecoration(
                    // Advertencia, no error de validación: color de estado
                    // (StatusTone.warning), no el rol `error` del ColorScheme.
                    color: warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'Crear una tarifa nueva de este tipo cerrará automáticamente la vigencia actual.',
                    style: TextStyle(color: warning),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<TipoVehiculo>(
                  initialValue: _tipoVehiculo,
                  decoration: const InputDecoration(labelText: 'Tipo de vehículo'),
                  items: [
                    for (final tipo in TipoVehiculo.values)
                      DropdownMenuItem(value: tipo, child: Text(tipoVehiculoLabel(tipo))),
                  ],
                  onChanged: state.isLoading
                      ? null
                      : (value) {
                          setState(() => _tipoVehiculo = value);
                          _onCamposCambiaron();
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _valorMinutoController,
                  enabled: !state.isLoading,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Valor por minuto'),
                  validator: requiredIntegerValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _valorPlenaController,
                  enabled: !state.isLoading,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Valor tarifa plena'),
                  validator: requiredIntegerValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _valorNocturnaController,
                  enabled: !state.isLoading,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Valor tarifa nocturna'),
                  validator: requiredIntegerValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _valorMesController,
                  enabled: !state.isLoading,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Valor mensualidad'),
                  validator: requiredIntegerValidator,
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<int>(
                  initialValue: _duracionMinutos,
                  decoration: const InputDecoration(labelText: 'Vista previa: duración de la estadía'),
                  items: [
                    for (final entry in _duracionesPreset.entries)
                      DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                  ],
                  onChanged: state.isLoading
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _duracionMinutos = value);
                          _onCamposCambiaron();
                        },
                ),
                const SizedBox(height: AppSpacing.sm),
                _PreviewSimulacion(
                  simulacion: ref.watch(tarifaSimulacionNotifierProvider),
                  tipoVehiculo: _tipoVehiculo,
                  duracionLabel: _duracionesPreset[_duracionMinutos]!,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading ? const ButtonSpinner() : const Text('Crear tarifa'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vista previa calculada por el backend (`POST /tarifas/simular`), no en el
/// cliente: es exactamente la vista previa que existió antes con cálculo
/// local y se eliminó por dar un número que no correspondía al cobro real
/// (ver CLAUDE.md), ahora con las reglas reales de bloques/nocturna/6 AM.
class _PreviewSimulacion extends StatelessWidget {
  const _PreviewSimulacion({required this.simulacion, required this.tipoVehiculo, required this.duracionLabel});

  final TarifaSimulacionState simulacion;
  final TipoVehiculo? tipoVehiculo;
  final String duracionLabel;

  @override
  Widget build(BuildContext context) {
    if (tipoVehiculo == null) {
      return const SizedBox.shrink();
    }
    if (simulacion.isLoading) {
      return const Row(
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: AppSpacing.sm),
          Text('Calculando vista previa…'),
        ],
      );
    }
    if (simulacion.errorMessage != null) {
      return Text(
        'No se pudo calcular la vista previa.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    if (!simulacion.tieneResultado) {
      return const SizedBox.shrink();
    }
    final valorTotal = simulacion.valorTotal;
    return Text(
      valorTotal != null
          ? 'Un ${tipoVehiculoLabel(tipoVehiculo!)} de $duracionLabel pagaría ${formatMoney(valorTotal)}.'
          : 'Para vehículos tipo Otro, el valor lo digita el operador al registrar la salida.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
