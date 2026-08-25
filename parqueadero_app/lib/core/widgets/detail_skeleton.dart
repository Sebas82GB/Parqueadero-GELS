import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'loading_skeleton.dart';

/// Imita la forma de una pantalla de detalle (chip(s) de estado arriba +
/// varias líneas de texto) para pantallas que cargan un solo recurso, en
/// vez de un spinner pelado.
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key, this.lineas = 4});

  final int lineas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingSkeleton(width: 96, height: 28, borderRadius: AppSpacing.lg),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < lineas; i++) ...[
            LoadingSkeleton(width: i.isEven ? 220 : 160, height: 14),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
