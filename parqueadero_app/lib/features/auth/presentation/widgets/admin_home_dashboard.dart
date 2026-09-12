import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/dashboard_action_group.dart';
import '../../../../core/widgets/dashboard_metric_card.dart';
import '../../../celdas/presentation/celda_list_notifier.dart';
import '../session_notifier.dart';

/// Home del ADMIN (skill `diseno-parqueadero`): reemplaza la lista plana de
/// botones que tenía antes `HomeScreen` por un dashboard agrupado por
/// función, mismo lenguaje visual que `OperadorHomeDashboard` (mismo
/// `maxWidth`, misma tarjeta de métrica generalizada a
/// `DashboardMetricCard`).
///
/// "Celdas ocupadas" comparte `celdaListNotifierProvider` con `CeldasScreen`
/// y `OperadorHomeDashboard` — mismo poll de 30s, ningún fetch duplicado.
///
/// "Ingresos de hoy" queda en placeholder ("—" vía `DashboardMetricCard` sin
/// `value`): no existe todavía una fuente de dato para esto. `totalRecaudado`
/// de un turno solo se persiste al cerrarlo (`turno.service.js`), así que
/// durante el día —con la mayoría de turnos `ABIERTO`— ese campo llega en
/// `null` desde `GET /turnos`, y no hay ningún endpoint de reporte que sume
/// ingresos en vivo entre operadores. Cablearlo de verdad exige un cambio en
/// `parqueadero-api`, fuera del alcance de esta app.
///
/// A diferencia del resto de las filas (siempre `verdeSenal`), "Cerrar
/// sesión" es una fila suelta con su propio borde y colores apagados: es una
/// acción distinta a navegar a una sección, no otro ítem de
/// `DashboardActionGroup`.
class AdminHomeDashboard extends ConsumerWidget {
  const AdminHomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final celdaState = ref.watch(celdaListNotifierProvider);
    final sinDatosTodavia = celdaState.celdas.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Parqueadero')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administrador',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Panel general',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.asfalto),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DashboardMetricCard(
                        label: 'Celdas ocupadas',
                        icon: Icons.local_parking,
                        dark: true,
                        value: sinDatosTodavia && (celdaState.isLoading || celdaState.errorMessage != null)
                            ? null
                            : celdaState.totalOcupadas,
                        suffix: ' / ${celdaState.totalCeldas}',
                        isLoading: celdaState.isLoading,
                        errorMessage: celdaState.errorMessage,
                        onRetry: () => ref.read(celdaListNotifierProvider.notifier).refrescar(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: DashboardMetricCard(label: 'Ingresos de hoy', icon: Icons.payments_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                DashboardActionGroup(
                  titulo: 'Operación',
                  items: [
                    DashboardActionItem(
                      icon: Icons.grid_view,
                      label: 'Ver celdas',
                      onTap: () => context.push('/celdas'),
                    ),
                    DashboardActionItem(
                      icon: Icons.search,
                      label: 'Buscar por placa',
                      onTap: () => context.push('/tickets/buscar'),
                    ),
                    DashboardActionItem(
                      icon: Icons.history,
                      label: 'Historial',
                      onTap: () => context.push('/tickets'),
                    ),
                    DashboardActionItem(
                      icon: Icons.schedule,
                      label: 'Turnos',
                      onTap: () => context.push('/turnos'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                DashboardActionGroup(
                  titulo: 'Configuración',
                  items: [
                    DashboardActionItem(icon: Icons.sell, label: 'Tarifas', onTap: () => context.push('/tarifas')),
                    DashboardActionItem(
                      icon: Icons.event_repeat,
                      label: 'Mensualidades',
                      onTap: () => context.push('/mensualidades'),
                    ),
                    DashboardActionItem(
                      icon: Icons.access_time,
                      label: 'Horario de operación',
                      onTap: () => context.push('/horarios'),
                    ),
                    DashboardActionItem(
                      icon: Icons.people,
                      label: 'Usuarios',
                      onTap: () => context.push('/usuarios'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _CerrarSesionRow(onTap: () => ref.read(sessionNotifierProvider.notifier).logout()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CerrarSesionRow extends StatelessWidget {
  const _CerrarSesionRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gris = Theme.of(context).colorScheme.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.linea, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.logout, color: gris, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Text('Cerrar sesión', style: TextStyle(color: gris, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
