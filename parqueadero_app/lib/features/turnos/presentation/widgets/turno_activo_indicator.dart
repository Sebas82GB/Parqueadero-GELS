import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/status_style.dart';
import '../../../../core/utils/bogota_time.dart';
import '../../../auth/domain/usuario.dart';
import '../../../auth/presentation/session_notifier.dart';
import '../../data/turno_repository_impl.dart';
import '../turno_activo_notifier.dart';

/// Hace notorio, antes de que el operador intente registrar una entrada o
/// una salida, si tiene o no un turno abierto. Solo aplica a `OPERADOR`: un
/// ADMIN nunca tiene turno propio (abrir turno es estrictamente `OPERADOR`
/// en el backend), así que acá no renderiza nada.
///
/// También es dueño de la pregunta "¿Iniciar turno?": apenas se detecta que
/// no hay uno (primera vez en el día que el operador entra), antes de
/// dejarlo hacer cualquier otra cosa, se le pregunta si quiere empezar.
/// "Iniciar" abre el turno con la baseInicial que configuró el ADMIN (el
/// operador nunca la digita acá); "No" lo devuelve al login. El backend
/// nunca abre un turno por su cuenta — ver
/// turno.service.js#resolverTurnoAutomatico en parqueadero-api. Este diálogo
/// vive acá (no en `OperadorHomeDashboard`) para no tener un segundo
/// observador de `turnoActivoNotifierProvider`: sea cual sea la causa exacta,
/// un segundo `ref.watch`/`ref.listen` del mismo provider desde otro widget
/// dejaba a `pumpAndSettle` esperando indefinidamente en los tests.
class TurnoActivoIndicator extends ConsumerStatefulWidget {
  const TurnoActivoIndicator({super.key});

  @override
  ConsumerState<TurnoActivoIndicator> createState() => _TurnoActivoIndicatorState();
}

class _TurnoActivoIndicatorState extends ConsumerState<TurnoActivoIndicator> {
  bool _dialogoMostrado = false;
  bool _preguntandoInicio = false;

  Future<void> _preguntarIniciarTurno() async {
    if (_preguntandoInicio) return;
    _preguntandoInicio = true;
    try {
      final confirmado = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('¿Iniciar turno?'),
          content: const Text('Vas a comenzar tu turno de hoy.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Iniciar')),
          ],
        ),
      );
      if (!mounted) return;

      if (confirmado != true) {
        await ref.read(sessionNotifierProvider.notifier).logout();
        return;
      }

      // Habla directo con el repositorio en vez de pasar por
      // AbrirTurnoNotifier: ese notifier es `autoDispose` y acá nadie lo
      // observa de forma persistente (a diferencia de `AbrirTurnoScreen`,
      // que sí lo mira con `ref.watch` todo el tiempo que está montada), así
      // que se corre el riesgo de perder el error entre el `await` y leer
      // su estado después.
      try {
        await ref.read(turnoRepositoryProvider).abrir();
        if (!mounted) return;
        await ref.read(turnoActivoNotifierProvider.notifier).refrescar();
      } on AppException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    } finally {
      _preguntandoInicio = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(sessionNotifierProvider).usuario;
    if (usuario == null || usuario.rol != RolUsuario.operador) return const SizedBox.shrink();

    final state = ref.watch(turnoActivoNotifierProvider);
    final notifier = ref.read(turnoActivoNotifierProvider.notifier);

    if (!_dialogoMostrado && !state.isLoading && state.errorMessage == null && state.turno == null) {
      _dialogoMostrado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _preguntarIniciarTurno();
      });
    }

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

    return _TurnoAbiertoBanner(
      text: 'Turno abierto desde ${formatBogota(turno.apertura)}',
      onVerArqueo: () => context.push('/turnos/${turno.id}'),
    );
  }
}

/// A diferencia de `_Banner` (que muestra estados genéricos con
/// `StatusStyle`), este aviso es siempre el mismo hecho — hay un turno
/// abierto — así que no necesita distinguirse de otro tono por matiz: lleva
/// la identidad de marca (asfalto/demarcación) en vez de la paleta de
/// estados. `demarcacion` pasa 10.6:1 de contraste sobre `asfalto`, muy por
/// encima de AA; también se usa en el link de acción porque `verdeSenal`
/// (el color de acción en el resto de la app) da solo ~2.7:1 ahí y no
/// pasaría el mismo estándar.
class _TurnoAbiertoBanner extends StatelessWidget {
  const _TurnoAbiertoBanner({required this.text, required this.onVerArqueo});

  final String text;
  final VoidCallback onVerArqueo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.asfalto,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.demarcacion, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.demarcacion)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.demarcacion),
            onPressed: onVerArqueo,
            child: const Text('Ver arqueo'),
          ),
        ],
      ),
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
