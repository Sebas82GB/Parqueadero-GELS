import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/animated_count_text.dart';
import '../../domain/celda.dart';
import 'celda_estado_style.dart';

/// El conteo que recibe SIEMPRE viene sin los filtros activos aplicados
/// (ver `CeldaListState.librresEnZona`/`totalEnZona`): la disponibilidad por
/// zona debe ser real, no la de la vista filtrada.
class ZonaHeader extends StatelessWidget {
  const ZonaHeader({
    super.key,
    required this.zona,
    required this.libres,
    required this.ocupadas,
    required this.mantenimiento,
    required this.total,
  });

  final String zona;
  final int libres;
  final int ocupadas;
  final int mantenimiento;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(zona, style: Theme.of(context).textTheme.titleLarge),
              Row(
                children: [
                  AnimatedCountText(value: libres, style: Theme.of(context).textTheme.bodyMedium),
                  Text('/$total libres', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _BarraOcupacion(libres: libres, ocupadas: ocupadas, mantenimiento: mantenimiento),
        ],
      ),
    );
  }
}

/// Barra de proporción de tres segmentos (mismos colores que
/// [CeldaEstadoStyle]), animada al cambiar las proporciones.
class _BarraOcupacion extends StatelessWidget {
  const _BarraOcupacion({required this.libres, required this.ocupadas, required this.mantenimiento});

  final int libres;
  final int ocupadas;
  final int mantenimiento;

  @override
  Widget build(BuildContext context) {
    final total = libres + ocupadas + mantenimiento;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        height: 4,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double anchoDe(int n) => total == 0 ? 0 : constraints.maxWidth * n / total;
            return Stack(
              children: [
                Container(color: Theme.of(context).colorScheme.surfaceContainerHigh),
                Row(
                  children: [
                    _Segmento(ancho: anchoDe(libres), color: CeldaEstadoStyle.of(EstadoCelda.libre).color),
                    _Segmento(ancho: anchoDe(ocupadas), color: CeldaEstadoStyle.of(EstadoCelda.ocupada).color),
                    _Segmento(
                      ancho: anchoDe(mantenimiento),
                      color: CeldaEstadoStyle.of(EstadoCelda.mantenimiento).color,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Segmento extends StatelessWidget {
  const _Segmento({required this.ancho, required this.color});

  final double ancho;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: ancho, end: ancho),
      duration: AppMotion.effective(context, AppMotion.medium),
      curve: AppMotion.curve,
      builder: (context, anchoActual, child) => Container(width: anchoActual, height: 4, color: color),
    );
  }
}
