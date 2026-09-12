import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/dashboard_metric_card.dart';
import '../../../celdas/presentation/celda_list_notifier.dart';
import '../../../turnos/presentation/widgets/turno_activo_indicator.dart';
import '../session_notifier.dart';

/// Home del OPERADOR (skill `diseno-parqueadero`): a diferencia del resto de
/// la app, acá SÍ hay dos acciones con peso visual propio (Registrar
/// entrada/salida) porque son la tarea que se repite decenas de veces por
/// turno — el resto de la pantalla se queda tranquilo.
///
/// "Registrar entrada" es la ruta rápida a `/tickets/entrada` sin
/// `celdaId`: `RegistrarEntradaScreen` asigna sola la primera celda LIBRE
/// compatible con el tipo elegido (ver su doc comment), así que el
/// operador no necesita pasar por la cuadrícula para el caso común. "Ver
/// celdas" sigue llevando a `/celdas` para cuando sí hace falta elegir una
/// celda específica a mano — mismo `RegistrarEntradaScreen`, esta vez con
/// `celdaId` porque se llega tocando una celda LIBRE puntual.
///
/// "Registrar salida" también lleva a `/celdas`: a diferencia de la
/// entrada, acá el operador SÍ sabe (o ve) en qué bahía física está el
/// vehículo que se va, así que elegirla a mano es lo natural. Tocar una
/// celda OCUPADA como OPERADOR ya abre el panel de acción rápida con
/// "Registrar salida y cobrar" (`celda_card.dart` → `showCeldaAccionRapida`)
/// — no hace falta ninguna pantalla nueva para esto. "Buscar placa" sigue
/// aparte, en `/tickets/buscar`: sirve para el caso en que el operador NO
/// sabe en qué celda quedó el vehículo, o para consultar uno que ya salió.
class OperadorHomeDashboard extends ConsumerWidget {
  const OperadorHomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parqueadero'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (opcion) {
              if (opcion == 'turnos') {
                context.push('/turnos');
              } else if (opcion == 'historial') {
                context.push('/tickets');
              } else if (opcion == 'salir') {
                ref.read(sessionNotifierProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'turnos', child: Text('Turnos')),
              PopupMenuItem(value: 'historial', child: Text('Historial')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'salir', child: Text('Cerrar sesión')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const TurnoActivoIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operador',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Hola, buen turno',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.asfalto),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _CeldasLibresCard(),
                      const SizedBox(height: AppSpacing.md),
                      _AccionPrincipal(
                        icon: Icons.add_box_outlined,
                        label: 'Registrar entrada',
                        fondo: AppColors.verdeSenal,
                        contenido: AppColors.concreto,
                        onTap: () => context.push('/tickets/entrada'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _AccionPrincipal(
                        icon: Icons.indeterminate_check_box_outlined,
                        label: 'Registrar salida',
                        fondo: AppColors.concreto,
                        contenido: AppColors.asfalto,
                        borde: AppColors.asfalto,
                        onTap: () => context.push('/celdas'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _AccionSecundaria(
                              icon: Icons.search,
                              label: 'Buscar placa',
                              onTap: () => context.push('/tickets/buscar'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _AccionSecundaria(
                              icon: Icons.grid_view,
                              label: 'Ver celdas',
                              onTap: () => context.push('/celdas'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Celdas libres" siempre en vivo: comparte `celdaListNotifierProvider` con
/// `CeldasScreen` (mismo `autoDispose` + poll de 30s), así que no duplica el
/// fetch — si ambas pantallas están montadas, un solo timer las alimenta.
/// Molde compartido con `AdminHomeDashboard` vía `DashboardMetricCard`.
class _CeldasLibresCard extends ConsumerWidget {
  const _CeldasLibresCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(celdaListNotifierProvider);
    final sinDatosTodavia = state.celdas.isEmpty;

    return DashboardMetricCard(
      label: 'Celdas libres',
      icon: Icons.local_parking,
      dark: true,
      value: sinDatosTodavia && (state.isLoading || state.errorMessage != null) ? null : state.totalLibres,
      suffix: ' / ${state.totalCeldas}',
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      onRetry: () => ref.read(celdaListNotifierProvider.notifier).refrescar(),
    );
  }
}

/// Botón de acción principal (Registrar entrada/salida): 56dp de alto —
/// objetivo táctil de botón principal, no el mínimo de 48dp — y radio 12,
/// distinto del radio 8 que usa `ElevatedButton` en el resto de la app, así
/// que se construye a mano en vez de heredar `elevatedButtonTheme`.
class _AccionPrincipal extends StatelessWidget {
  const _AccionPrincipal({
    required this.icon,
    required this.label,
    required this.fondo,
    required this.contenido,
    required this.onTap,
    this.borde,
  });

  final IconData icon;
  final String label;
  final Color fondo;
  final Color contenido;
  final Color? borde;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fondo,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: borde == null ? null : Border.all(color: borde!, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: contenido, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: TextStyle(color: contenido, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta secundaria (Buscar placa/Ver celdas): mismo lenguaje tranquilo que
/// el resto de la app fuera de la cuadrícula — `concreto` con borde `linea`,
/// sin ningún acento de `demarcacion` que compita con las acciones
/// principales de arriba.
class _AccionSecundaria extends StatelessWidget {
  const _AccionSecundaria({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.concreto,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.linea, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.verdeSenal, size: 18),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: const TextStyle(color: AppColors.asfalto, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
