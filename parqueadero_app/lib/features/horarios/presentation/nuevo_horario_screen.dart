import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/status_style.dart';
import '../../../core/widgets/acceso_restringido.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import 'nuevo_horario_notifier.dart';

/// Firma inyectable de la selección de hora: en producción abre el picker
/// nativo de Flutter; en widget tests se overridea para devolver una
/// [TimeOfDay] fija sin abrir el diálogo real (no hay precedente en este
/// proyecto de testear el árbol interno de `TimePickerDialog`, y hacerlo
/// sería frágil entre versiones del SDK).
typedef SeleccionarHora = Future<TimeOfDay?> Function(BuildContext context, TimeOfDay? inicial, String helpText);

Future<TimeOfDay?> _seleccionarHoraPorDefecto(BuildContext context, TimeOfDay? inicial, String helpText) {
  return showTimePicker(
    context: context,
    initialTime: inicial ?? TimeOfDay.now(),
    // Campos de texto para hora/minuto en vez del dial: más rápido y preciso
    // a una mano bajo sol directo (contexto de uso documentado en la skill
    // de diseño).
    initialEntryMode: TimePickerEntryMode.input,
    helpText: helpText,
    // Fuerza formato 24h sin depender de la configuración del dispositivo:
    // el valor mostrado y el que se envía al backend deben ser el mismo
    // "HH:mm", sin ambigüedad de AM/PM.
    builder: (context, child) =>
        MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
  );
}

String _formatHora(TimeOfDay hora) =>
    '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';

class NuevoHorarioScreen extends ConsumerStatefulWidget {
  const NuevoHorarioScreen({super.key, this.seleccionarHora = _seleccionarHoraPorDefecto});

  final SeleccionarHora seleccionarHora;

  @override
  ConsumerState<NuevoHorarioScreen> createState() => _NuevoHorarioScreenState();
}

class _NuevoHorarioScreenState extends ConsumerState<NuevoHorarioScreen> {
  TimeOfDay? _apertura;
  TimeOfDay? _cierre;
  String? _errorHora;

  Future<void> _elegirApertura() async {
    final hora = await widget.seleccionarHora(context, _apertura, 'Hora de apertura');
    if (hora == null) return;
    setState(() {
      _apertura = hora;
      _errorHora = null;
    });
  }

  Future<void> _elegirCierre() async {
    final hora = await widget.seleccionarHora(context, _cierre, 'Hora de cierre');
    if (hora == null) return;
    setState(() {
      _cierre = hora;
      _errorHora = null;
    });
  }

  Future<void> _submit() async {
    final apertura = _apertura;
    final cierre = _cierre;
    if (apertura == null || cierre == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona la hora de apertura y de cierre.')));
      return;
    }

    final aperturaStr = _formatHora(apertura);
    final cierreStr = _formatHora(cierre);
    // Misma comparación que el `.refine()` de `crearHorarioBodySchema` en el
    // backend (`cierre > apertura` como string `HH:mm`): feedback inmediato
    // sin esperar el round-trip.
    if (cierreStr.compareTo(aperturaStr) <= 0) {
      setState(() => _errorHora = 'La hora de cierre debe ser posterior a la de apertura.');
      return;
    }
    setState(() => _errorHora = null);

    final horario = await ref
        .read(nuevoHorarioNotifierProvider.notifier)
        .crear(apertura: aperturaStr, cierre: cierreStr);
    if (horario == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Horario creado'),
        content: const Text(
          'El nuevo horario ya está vigente. El horario anterior, si existía, quedó cerrado; '
          'los tickets con entrada ya registrada conservan el horario con el que entraron.',
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
        appBar: AppBar(title: const Text('Nuevo horario')),
        body: const AccesoRestringido(),
      );
    }

    final state = ref.watch(nuevoHorarioNotifierProvider);
    final warning = StatusStyle.of(StatusTone.warning).color;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo horario')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
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
                  'Crear un horario nuevo cierra automáticamente el vigente actual. Los tickets que ya '
                  'tienen una entrada registrada conservan el horario con el que entraron; esto no los afecta.',
                  style: TextStyle(color: warning),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SelectorHora(
                label: 'Apertura',
                hora: _apertura,
                enabled: !state.isLoading,
                onTap: _elegirApertura,
              ),
              const SizedBox(height: AppSpacing.md),
              _SelectorHora(label: 'Cierre', hora: _cierre, enabled: !state.isLoading, onTap: _elegirCierre),
              if (_errorHora != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_errorHora!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
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
                child: state.isLoading ? const ButtonSpinner() : const Text('Crear horario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorHora extends StatelessWidget {
  const _SelectorHora({required this.label, required this.hora, required this.enabled, required this.onTap});

  final String label;
  final TimeOfDay? hora;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('selector-hora-$label'),
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.access_time)),
        child: Text(
          hora == null ? 'Toca para elegir hora' : _formatHora(hora!),
          style: hora == null ? TextStyle(color: Theme.of(context).colorScheme.outline) : null,
        ),
      ),
    );
  }
}
