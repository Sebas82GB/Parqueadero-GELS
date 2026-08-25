import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/status_style.dart';
import '../../../core/utils/bogota_time.dart';
import '../../../core/widgets/acceso_restringido.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import '../domain/horario.dart';
import 'horario_list_notifier.dart';

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
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (vigente != null) _VigenteCard(horario: vigente) else const _SinVigenteAviso(),
            if (historico.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Histórico', style: Theme.of(context).textTheme.titleMedium),
              for (final h in historico) _HistoricoRow(horario: h),
            ],
          ],
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

class _VigenteCard extends StatelessWidget {
  const _VigenteCard({required this.horario});

  final Horario horario;

  @override
  Widget build(BuildContext context) {
    final success = StatusStyle.of(StatusTone.success).color;
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
          ],
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
