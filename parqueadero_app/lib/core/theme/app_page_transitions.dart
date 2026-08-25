import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Transición de página única para toda la app. Cada `GoRoute` de
/// `app_router.dart` usa `builder:` (no `pageBuilder:`), y go_router envuelve
/// ese `builder` en una page que respeta `Theme.of(context).pageTransitionsTheme`
/// — por eso esto se centraliza acá en vez de convertir cada una de las
/// rutas a `CustomTransitionPage`.
///
/// Fundido + deslizamiento vertical sutil, con la única curva de movimiento
/// del proyecto (`AppMotion.curve`, sin rebote). Si el sistema pide
/// movimiento reducido, la página aparece sin transición.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) {
      return child;
    }

    final curved = CurvedAnimation(parent: animation, curve: AppMotion.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
