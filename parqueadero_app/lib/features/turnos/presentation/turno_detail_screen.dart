import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/session_notifier.dart';
import '../domain/turno.dart';
import 'turno_detail_notifier.dart';
import 'widgets/arqueo_summary_view.dart';
import 'widgets/turno_kpis_view.dart';

class TurnoDetailScreen extends ConsumerWidget {
  const TurnoDetailScreen({super.key, required this.turnoId});

  final String turnoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(turnoDetailNotifierProvider(turnoId));

    Widget body;
    if (state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.errorMessage != null) {
      body = ErrorState(
        message: state.errorMessage!,
        onRetry: ref.read(turnoDetailNotifierProvider(turnoId).notifier).cargar,
      );
    } else {
      final arqueo = state.arqueo!;
      final usuario = ref.watch(sessionNotifierProvider).usuario;
      final puedeCerrar =
          arqueo.estado == EstadoTurno.abierto &&
          usuario != null &&
          (usuario.id == arqueo.operadorId || usuario.rol == RolUsuario.admin);
      // A diferencia de cerrar, completar el arqueo pendiente es siempre
      // ADMIN-only: el backend no tiene excepción para el operador dueño acá
      // porque esta validación ES el control diario que pide el negocio.
      final puedeCompletarArqueo =
          arqueo.estado == EstadoTurno.cerradoPendienteArqueo &&
          usuario != null &&
          usuario.rol == RolUsuario.admin;

      body = SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TurnoKpisView(arqueo: arqueo, ahora: DateTime.now()),
              const SizedBox(height: AppSpacing.lg),
              ArqueoSummaryView(arqueo: arqueo),
              if (puedeCerrar) ...[
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => context.push('/turnos/$turnoId/cerrar'),
                  child: const Text('Cerrar turno'),
                ),
              ],
              if (puedeCompletarArqueo) ...[
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => context.push('/turnos/$turnoId/cerrar'),
                  child: const Text('Completar arqueo'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Turno')), body: body);
  }
}
