import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/status_style.dart';
import '../../../core/utils/bogota_time.dart';
import '../../../core/widgets/acceso_restringido.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import '../domain/horario.dart';
import 'horario_accion_notifier.dart';
import 'horario_list_notifier.dart';
import 'seleccionar_hora.dart';

class HorariosScreen extends ConsumerWidget {
  const HorariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Se observa sin condición, antes de cualquier early-return: si quedara
    // detrás de un `if`, la restauración de sesión no arrancaría hasta que
    // el resto de la pantalla ya estuviera construido.
    final esAdmin = ref.watch(sessionNotifierProvider).usuario?.rol == RolUsuario.admin;

    if (!esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Horario de operación')),
        body: const AccesoRestringido(),
      );
    }

    final state = ref.watch(horarioListNotifierProvider);
    final notifier = ref.read(horarioListNotifierProvider.notifier);

    Widget body;
    if (state.horarios.isEmpty && state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.horarios.isEmpty && state.errorMessage != null) {
      body = ErrorState(message: state.errorMessage!, onRetry: notifier.refrescar);
    } else if (state.horarios.isEmpty) {
      body = EmptyState(
        icon: Icons.schedule,
        message: 'No hay horarios configurados.',
        actionLabel: 'Crear horario',
        onAction: () => context.push('/horarios/nuevo'),
      );
    } else {
      final vigente = state.vigente;
      final historico = state.historico;
      body = RefreshIndicator(
        onRefresh: notifier.refrescar,
        // `.builder` y no `ListView(children: [...])`: el histórico no tiene
        // cota — `HorarioRepositoryImpl.listarTodas()` recorre todas las
        // páginas — y como lista eager se construía entero aunque solo se
        // vieran las primeras filas.
        child: ListView.builder(
          // Imprescindible: si el contenido cabe sin scroll, el
          // pull-to-refresh no dispara sin esta física.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          // Índice 0 = cabecera (vigente + título); el resto, una fila de
          // histórico cada uno, desplazadas en 1.
          itemCount: 1 + historico.length,
          itemBuilder: (context, index) {
            if (index > 0) return _HistoricoRow(horario: historico[index - 1]);
            return Column(
              // `ListView` estira a sus hijos al ancho completo; una `Column`
              // los centraría. Sin esto la tarjeta del vigente encogería a su
              // contenido.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (vigente != null) _VigenteCard(horario: vigente) else const _SinVigenteAviso(),
                if (historico.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text('Histórico', style: Theme.of(context).textTheme.titleMedium),
                ],
              ],
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario de operación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo horario',
            onPressed: () => context.push('/horarios/nuevo'),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _VigenteCard extends ConsumerWidget {
  const _VigenteCard({required this.horario});

  final Horario horario;

  Future<void> _confirmarCerrar(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar vigencia?'),
        content: Text(
          'El horario ${horario.apertura} – ${horario.cierre} vigente desde '
          '${formatBogota(horario.vigenteDesde, 'd MMM y')} dejará de aplicar de inmediato y no se '
          'reemplaza por otro. El parqueadero quedará sin horario de operación activo hasta que crees uno nuevo. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmado != true) return;
    // HorarioAccionNotifier.cerrar() ya refresca horarioListNotifierProvider
    // por sí solo en caso de éxito.
    await ref.read(horarioAccionNotifierProvider(horario.id).notifier).cerrar();
  }

  Future<void> _editar(BuildContext context, WidgetRef ref) async {
    final cambios = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _EditarHorarioDialog(horario: horario),
    );
    // Diálogo cancelado, o sin cambios (el propio diálogo ya evita llamar al
    // backend con un body vacío, que el validador `.strict()` rechaza).
    if (cambios == null || cambios.isEmpty) return;
    // HorarioAccionNotifier.actualizar() ya refresca
    // horarioListNotifierProvider por sí solo en caso de éxito.
    await ref
        .read(horarioAccionNotifierProvider(horario.id).notifier)
        .actualizar(apertura: cambios['apertura'], cierre: cambios['cierre']);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final success = StatusStyle.of(StatusTone.success).color;
    final accion = ref.watch(horarioAccionNotifierProvider(horario.id));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: const Text('Vigente'),
                  backgroundColor: success.withValues(alpha: 0.12),
                  side: BorderSide(color: success),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Desde ${formatBogota(horario.vigenteDesde, 'd MMM y')}'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${horario.apertura} – ${horario.cierre}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (accion.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(accion.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: accion.isLoading ? null : () => _editar(context, ref),
                    child: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: accion.isLoading ? null : () => _confirmarCerrar(context, ref),
                    child: accion.isLoading ? const ButtonSpinner(size: 20) : const Text('Cerrar vigencia'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo de edición del horario vigente. Devuelve un `Map` con solo los
/// campos que cambiaron respecto a [horario] (vacío si no cambió ninguno):
/// el llamador decide, con ese resultado, si vale la pena llamar al
/// backend — que rechaza con 400 un body vacío.
class _EditarHorarioDialog extends StatefulWidget {
  const _EditarHorarioDialog({required this.horario});

  final Horario horario;

  @override
  State<_EditarHorarioDialog> createState() => _EditarHorarioDialogState();
}

class _EditarHorarioDialogState extends State<_EditarHorarioDialog> {
  late TimeOfDay _apertura = _parseHora(widget.horario.apertura);
  late TimeOfDay _cierre = _parseHora(widget.horario.cierre);
  String? _errorHora;

  static TimeOfDay _parseHora(String hora) {
    final partes = hora.split(':');
    return TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
  }

  Future<void> _elegirApertura() async {
    final hora = await seleccionarHoraPorDefecto(context, _apertura, 'Hora de apertura');
    if (hora == null) return;
    setState(() {
      _apertura = hora;
      _errorHora = null;
    });
  }

  Future<void> _elegirCierre() async {
    final hora = await seleccionarHoraPorDefecto(context, _cierre, 'Hora de cierre');
    if (hora == null) return;
    setState(() {
      _cierre = hora;
      _errorHora = null;
    });
  }

  void _guardar() {
    final aperturaStr = formatHora(_apertura);
    final cierreStr = formatHora(_cierre);
    // Misma comparación que el `.refine()` de `actualizarHorarioBodySchema`
    // en el backend (`cierre > apertura` como string `HH:mm`): feedback
    // inmediato sin esperar el round-trip.
    if (cierreStr.compareTo(aperturaStr) <= 0) {
      setState(() => _errorHora = 'La hora de cierre debe ser posterior a la de apertura.');
      return;
    }
    final cambios = <String, String>{
      if (aperturaStr != widget.horario.apertura) 'apertura': aperturaStr,
      if (cierreStr != widget.horario.cierre) 'cierre': cierreStr,
    };
    Navigator.of(context).pop(cambios);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar horario'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SelectorHora(label: 'Apertura', hora: _apertura, enabled: true, onTap: _elegirApertura),
          const SizedBox(height: AppSpacing.md),
          _SelectorHora(label: 'Cierre', hora: _cierre, enabled: true, onTap: _elegirCierre),
          if (_errorHora != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_errorHora!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
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

class _SinVigenteAviso extends StatelessWidget {
  const _SinVigenteAviso();

  @override
  Widget build(BuildContext context) {
    final warning = StatusStyle.of(StatusTone.warning).color;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(color: warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(
        'Sin horario vigente — el parqueadero no tiene un horario de operación activo hasta que crees uno.',
        style: TextStyle(color: warning),
      ),
    );
  }
}

class _HistoricoRow extends StatelessWidget {
  const _HistoricoRow({required this.horario});

  final Horario horario;

  @override
  Widget build(BuildContext context) {
    final rango = horario.vigenteHasta == null
        ? 'Desde ${formatBogota(horario.vigenteDesde, 'd MMM y')}'
        : '${formatBogota(horario.vigenteDesde, 'd MMM y')} – ${formatBogota(horario.vigenteHasta!, 'd MMM y')}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${horario.apertura} – ${horario.cierre}'),
      subtitle: Text(rango),
    );
  }
}
