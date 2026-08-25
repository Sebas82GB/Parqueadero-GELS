import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Un conteo simple (celdas libres, tickets, etc.) que cuenta hacia el valor
/// nuevo en vez de saltar. Solo para conteos de listas ya cargadas — nunca
/// para montos de dinero ni valores que calcule el backend.
class AnimatedCountText extends StatelessWidget {
  const AnimatedCountText({super.key, required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: value, end: value),
      duration: AppMotion.effective(context, AppMotion.medium),
      curve: AppMotion.curve,
      builder: (context, valorActual, child) => Text('$valorActual', style: style),
    );
  }
}
