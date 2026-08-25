import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'loading_skeleton.dart';

/// Imita la forma de una fila de listado (`Card` + `ListTile`: título,
/// subtítulo más angosto, chip a la derecha) para pantallas que cargan una
/// lista, en vez de un spinner pelado.
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(width: 120, height: 16),
                  SizedBox(height: AppSpacing.sm),
                  LoadingSkeleton(width: 180, height: 12),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const LoadingSkeleton(width: 72, height: 28, borderRadius: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
