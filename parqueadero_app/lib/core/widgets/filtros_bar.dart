import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Andamiaje común de las barras de filtro: cada feature sigue construyendo
/// sus propios dropdowns/campos, esto solo unifica el `Padding` + `Wrap` que
/// los envuelve.
class FiltrosBar extends StatelessWidget {
  const FiltrosBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}
