import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// Caja rectangular con un pulso de opacidad, para dar la sensación de
/// contenido cargando sin un spinner pelado. Reutilizable por cualquier
/// feature que necesite un placeholder de carga.
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({super.key, this.width, this.height, this.borderRadius = AppRadius.sm});

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.4,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
