import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_count_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../turnos/presentation/widgets/turno_activo_indicator.dart';
import '../domain/celda.dart';
import 'celda_list_notifier.dart';
import 'widgets/celda_card.dart';
import 'widgets/celda_estado_style.dart';
import 'widgets/celda_filtros_bar.dart';
import 'widgets/celda_grid_skeleton.dart';
import 'widgets/zona_header.dart';

class CeldasScreen extends ConsumerStatefulWidget {
  const CeldasScreen({super.key});

  @override
  ConsumerState<CeldasScreen> createState() => _CeldasScreenState();
}

class _CeldasScreenState extends ConsumerState<CeldasScreen> with SingleTickerProviderStateMixin {
  /// Único controller para la animación de entrada de TODA la grilla — ver
  /// doc de `CeldaCard.entrada`. Arranca una sola vez, la primera vez que
  /// hay celdas para mostrar; una celda agregada después con la pantalla ya
  /// abierta no vuelve a dispararlo (haría falta rastrear qué ids ya se
  /// vieron). Se acepta ese caso raro sin animación de entrada propia a
  /// cambio de no instanciar un controller por tarjeta en la carga inicial,
  /// que es el caso que de verdad importa.
  late final AnimationController _entradaController;
  bool _entradaDisparada = false;

  @override
  void initState() {
    super.initState();
    // Construido acá, no en el inicializador de un `late final` perezoso:
    // si `celdas` nunca deja de estar vacía (loading/error/vacío) `build()`
    // nunca llega a tocar el campo, y `AnimationController(vsync: this)`
    // dentro del inicializador lazy solo se dispararía al acceder desde
    // `dispose()` — con el elemento ya desactivado, esa creación (busca su
    // `TickerMode` ancestro) es insegura y tira "deactivated widget's
    // ancestor is unsafe".
    _entradaController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: CeldaCard.totalMs),
    );
  }

  @override
  void dispose() {
    _entradaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(celdaListNotifierProvider);
    final notifier = ref.read(celdaListNotifierProvider.notifier);

    if (!_entradaDisparada && state.celdas.isNotEmpty) {
      _entradaDisparada = true;
      _entradaController.forward();
    }

    Widget body;
    if (state.celdas.isEmpty && state.isLoading) {
      body = const CeldaGridSkeleton();
    } else if (state.celdas.isEmpty && state.errorMessage != null) {
      body = ErrorState(message: state.errorMessage!, onRetry: notifier.refrescar);
    } else if (state.celdas.isEmpty) {
      body = const EmptyState(
        icon: Icons.local_parking,
        message: 'No hay celdas registradas en el parqueadero.',
      );
    } else {
      final grupos = state.celdasFiltradasPorZona;
      body = RefreshIndicator(
        onRefresh: notifier.refrescar,
        child: CustomScrollView(
          // Imprescindible: si el contenido cabe sin scroll, el
          // pull-to-refresh no dispara sin esta física.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Buscador + chips arriba del todo (rediseño), el resumen de
            // contadores queda justo debajo.
            const SliverToBoxAdapter(child: CeldaFiltrosBar()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 0),
                child: Row(
                  children: [
                    _EstadoStat(
                      key: const Key('resumen-libre'),
                      estado: EstadoCelda.libre,
                      count: state.totalLibres,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _EstadoStat(
                      key: const Key('resumen-ocupada'),
                      estado: EstadoCelda.ocupada,
                      count: state.totalOcupadas,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _EstadoStat(
                      key: const Key('resumen-mantenimiento'),
                      estado: EstadoCelda.mantenimiento,
                      count: state.totalMantenimiento,
                    ),
                  ],
                ),
              ),
            ),
            if (grupos.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.filter_alt_off,
                  message: 'Ningún resultado coincide con los filtros.',
                  actionLabel: 'Limpiar filtros',
                  onAction: notifier.limpiarFiltros,
                ),
              )
            else
              for (final zona in grupos.keys) ...[
                SliverToBoxAdapter(
                  child: ZonaHeader(
                    zona: zona,
                    libres: state.librresEnZona(zona),
                    ocupadas: state.ocupadasEnZona(zona),
                    mantenimiento: state.mantenimientoEnZona(zona),
                    total: state.totalEnZona(zona),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => CeldaCard(
                        key: ValueKey(grupos[zona]![i].id),
                        celdaId: grupos[zona]![i].id,
                        entryIndex: i,
                        entrada: _entradaController,
                      ),
                      childCount: grupos[zona]!.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
              ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Celdas')),
      body: Column(
        children: [
          const TurnoActivoIndicator(),
          Expanded(
            // Centrado con ancho máximo en pantallas anchas (web/escritorio):
            // el grid delegate ya agrega columnas solo al crecer el ancho
            // disponible, esto solo evita que crezca sin límite.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppBreakpoints.gridMaxWidth),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoStat extends StatelessWidget {
  const _EstadoStat({super.key, required this.estado, required this.count});

  final EstadoCelda estado;
  final int count;

  @override
  Widget build(BuildContext context) {
    final style = CeldaEstadoStyle.of(estado);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(style.icon, color: style.color, size: 18),
        const SizedBox(width: AppSpacing.xs),
        // Sin teñir con style.color (ver celda_card.dart): el ícono ya
        // comunica el estado, el número se queda en el color por defecto.
        AnimatedCountText(value: count, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: AppSpacing.xs),
        Text(style.label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
