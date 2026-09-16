import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Leyenda de estados de celda para la cuadrícula.
///
/// Explica el código visual de las bahías (relleno y borde, no matices de
/// color) mediante mini-bahías que replican la apariencia de `CeldaCard`.
class CeldaLeyenda extends StatelessWidget {
  const CeldaLeyenda({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: const [
          _MiniBahiaItem(
            tipo: _TipoMiniBahia.libre,
            label: 'Libre',
          ),
          _MiniBahiaItem(
            tipo: _TipoMiniBahia.ocupada,
            label: 'Ocupada',
          ),
          _MiniBahiaItem(
            tipo: _TipoMiniBahia.mantenimiento,
            label: 'Mantenimiento',
          ),
        ],
      ),
    );
  }
}

enum _TipoMiniBahia { libre, ocupada, mantenimiento }

class _MiniBahiaItem extends StatelessWidget {
  const _MiniBahiaItem({
    required this.tipo,
    required this.label,
  });

  final _TipoMiniBahia tipo;
  final String label;

  static const double _lado = 20.0;

  @override
  Widget build(BuildContext context) {
    final Widget miniBahia = switch (tipo) {
      _TipoMiniBahia.libre => ExcludeSemantics(
          child: Container(
            width: _lado,
            height: _lado,
            decoration: BoxDecoration(
              color: AppColors.asfaltoOscuro,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.amarilloPastel, width: 2),
            ),
          ),
        ),
      _TipoMiniBahia.ocupada => ExcludeSemantics(
          child: Container(
            width: _lado,
            height: _lado,
            decoration: BoxDecoration(
              color: AppColors.asfaltoMedio,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.amarilloPastel),
            ),
          ),
        ),
      _TipoMiniBahia.mantenimiento => ExcludeSemantics(
          child: Container(
            width: _lado,
            height: _lado,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.asfaltoClaro),
            ),
            child: const CustomPaint(
              painter: _LeyendaHatchPainter(),
            ),
          ),
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        miniBahia,
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Rayado diagonal de MANTENIMIENTO a escala reducida para la leyenda.
class _LeyendaHatchPainter extends CustomPainter {
  const _LeyendaHatchPainter();

  static const double _grosor = 3;
  static const double _paso = _grosor * 2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.asfaltoOscuro,
    );

    final raya = Paint()
      ..color = AppColors.asfaltoClaro
      ..style = PaintingStyle.stroke
      ..strokeWidth = _grosor;

    for (double x = -size.height; x < size.width + size.height; x += _paso) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), raya);
    }
  }

  @override
  bool shouldRepaint(covariant _LeyendaHatchPainter oldDelegate) => false;
}
