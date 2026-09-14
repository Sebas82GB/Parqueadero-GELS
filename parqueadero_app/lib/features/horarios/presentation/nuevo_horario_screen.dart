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
import 'seleccionar_hora.dart';

// Re-exportado: los tests existentes importan `SeleccionarHora` desde este
// archivo (antes definido acá mismo, ahora compartido con el diálogo de
// edición de `HorariosScreen`).
export 'seleccionar_hora.dart';

class NuevoHorarioScreen extends ConsumerStatefulWidget {
  const NuevoHorarioScreen({super.key, this.seleccionarHora = seleccionarHoraPorDefecto});

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

    final aperturaStr = formatHora(apertura);
    final cierreStr = formatHora(cierre);
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
          hora == null ? 'Toca para elegir hora' : formatHora(hora!),
          style: hora == null ? TextStyle(color: Theme.of(context).colorScheme.outline) : null,
        ),
      ),
    );
  }
}
