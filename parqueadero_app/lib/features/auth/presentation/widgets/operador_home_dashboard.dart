import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/animated_count_text.dart';
import '../../../celdas/presentation/celda_list_notifier.dart';
import '../../../turnos/presentation/widgets/turno_activo_indicator.dart';
import '../session_notifier.dart';

/// Home del OPERADOR (skill `diseno-parqueadero`): a diferencia del resto de
/// la app, acá SÍ hay dos acciones con peso visual propio (Registrar
/// entrada/salida) porque son la tarea que se repite decenas de veces por
/// turno — el resto de la pantalla se queda tranquilo.
///
/// "Registrar entrada" y "Ver celdas" llevan al mismo `/celdas`:
/// `RegistrarEntradaScreen` exige llegar con un `celdaId` (se toma de un tap
/// en una celda LIBRE de la cuadrícula, nunca de un selector propio — ver su
/// doc comment), así que no hay una ruta de "registrar entrada" sin pasar
/// por ahí. Mismo caso con "Registrar salida" y "Buscar placa": ambos llevan
/// a `/tickets/buscar`, la única pantalla que resuelve "¿qué ticket cierro?"
/// buscando por placa. No son accesos duplicados por error: son la misma
/// pantalla con distinta prioridad visual según la intención del operador.
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
                        onTap: () => context.push('/celdas'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _AccionPrincipal(
                        icon: Icons.indeterminate_check_box_outlined,
                        label: 'Registrar salida',
                        fondo: AppColors.concreto,
                        contenido: AppColors.asfalto,
                        borde: AppColors.asfalto,
                        onTap: () => context.push('/tickets/buscar'),
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
class _CeldasLibresCard extends ConsumerWidget {
  const _CeldasLibresCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(celdaListNotifierProvider);
    final sinDatosTodavia = state.celdas.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.asfalto, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Celdas libres', style: TextStyle(color: AppColors.demarcacion, fontSize: 11)),
                const SizedBox(height: AppSpacing.xs),
                if (sinDatosTodavia && state.isLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.demarcacion),
                    ),
                  )
                else if (sinDatosTodavia && state.errorMessage != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.demarcacion, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: AppColors.demarcacion),
                        onPressed: () => ref.read(celdaListNotifierProvider.notifier).refrescar(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedCountText(
                        value: state.totalLibres,
                        style: const TextStyle(color: AppColors.demarcacion, fontSize: 28),
                      ),
                      Text(
                        ' / ${state.totalCeldas}',
                        style: const TextStyle(color: AppColors.concreto, fontSize: 15),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Icon(Icons.local_parking, color: AppColors.demarcacion.withValues(alpha: 0.7), size: 28),
        ],
      ),
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
