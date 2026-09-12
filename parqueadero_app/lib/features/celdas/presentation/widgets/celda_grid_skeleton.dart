import 'package:flutter/material.dart';

import '../../../../core/theme/app_elevation.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/loading_skeleton.dart';

/// Simula la grilla mientras carga: una mini-tarjeta por celda (círculo de
/// ícono + dos líneas cortas), con la misma forma general que [CeldaCard]
/// en vez de un rectángulo genérico.
class CeldaGridSkeleton extends StatelessWidget {
  const CeldaGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1,
      ),
      itemCount: 8,
      itemBuilder: (context, index) => Card(
        margin: EdgeInsets.zero,
        elevation: AppElevation.flat,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingSkeleton(width: 32, height: 32, borderRadius: 16),
              SizedBox(height: AppSpacing.sm),
              LoadingSkeleton(width: 48, height: 12),
              SizedBox(height: AppSpacing.xs),
              LoadingSkeleton(width: 36, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Se usa en vez de [CeldaGridSkeleton] cuando esta sesión ya mostró la
/// grilla con datos reales al menos una vez (ver
/// `celdaGridYaVioDatosProvider` en `celdas_screen.dart`) y
/// `celdaListNotifierProvider` volvió a arrancar desde cero por su
/// `autoDispose`: el fetch debería resolver rápido, así que repetir las 8
/// tarjetas fantasma se sentiría como un parpadeo, no como una carga real.
class CeldaGridRecargaSilenciosa extends StatelessWidget {
  const CeldaGridRecargaSilenciosa({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
