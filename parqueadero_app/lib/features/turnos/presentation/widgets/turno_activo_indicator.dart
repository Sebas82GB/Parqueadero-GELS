import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/status_style.dart';
import '../../../../core/utils/bogota_time.dart';
import '../../../auth/domain/usuario.dart';
import '../../../auth/presentation/session_notifier.dart';
import '../turno_activo_notifier.dart';

/// Hace notorio, antes de que el operador intente registrar una entrada o
/// una salida, si tiene o no un turno abierto. Solo aplica a `OPERADOR`: un
/// ADMIN nunca tiene turno propio (abrir turno es estrictamente `OPERADOR`
/// en el backend), así que acá no renderiza nada.
class TurnoActivoIndicator extends ConsumerWidget {
  const TurnoActivoIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(sessionNotifierProvider).usuario;
    if (usuario == null || usuario.rol != RolUsuario.operador) return const SizedBox.shrink();

    final state = ref.watch(turnoActivoNotifierProvider);
    final notifier = ref.read(turnoActivoNotifierProvider.notifier);

    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (state.errorMessage != null) {
      return _Banner(
        style: StatusStyle.of(StatusTone.danger),
        text: state.errorMessage!,
        actionLabel: 'Reintentar',
        onAction: notifier.refrescar,
      );
    }

    final turno = state.turno;
    if (turno == null) {
      return _Banner(
        style: StatusStyle.of(StatusTone.warning),
        text: 'Sin turno abierto',
        actionLabel: 'Abrir turno',
        onAction: () => context.push('/turnos/abrir'),
      );
    }

    return _Banner(
      style: StatusStyle.of(StatusTone.info),
      text: 'Turno abierto desde ${formatBogota(turno.apertura)}',
      actionLabel: 'Ver arqueo',
      onAction: () => context.push('/turnos/${turno.id}'),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.style, required this.text, required this.actionLabel, required this.onAction});

  final StatusStyle style;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(style.icon, color: style.color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          // Sin teñir con style.color (ver celda_card.dart): el ícono ya
          // comunica el estado, el texto se queda en el color por defecto.
          Expanded(child: Text(text)),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
