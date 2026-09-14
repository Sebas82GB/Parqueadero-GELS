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

  /// Sin este override, la clase base `PageTransitionsBuilder` del SDK
  /// declara 300 ms, y ese valor es el que termina usando cada ruta a
  /// través de `MaterialPage.transitionDuration` — incluso las de
  /// `app_router.dart`, que se declaran con `builder:` y no con
  /// `pageBuilder:`. Por eso alcanza con sobreescribirlo acá y NO hace
  /// falta convertir ninguna ruta a `CustomTransitionPage`.
  ///
  /// `AppMotion.medium` ya se documentaba a sí mismo como "Transición de
  /// página (`AppPageTransitionsBuilder`)", pero sin este override el token
  /// era decorativo: de él solo se consumía la curva, nunca la duración, y
  /// el movimiento quedaba fuera del rango de 150-250 ms del sistema de
  /// diseño.
  @override
  Duration get transitionDuration => AppMotion.medium;

  @override
  Duration get reverseTransitionDuration => AppMotion.medium;

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

    // La ruta que ya terminó de entrar y solo está siendo tapada por otra
    // empujada encima llega acá con `animation` estático en 1.0 (nunca
    // vuelve a moverse mientras espera): envolverla en FadeTransition no
    // cambia nada visible (opacidad ya fija en 1.0, offset ya en 0,0), pero
    // sí fuerza una capa de composición sobre todo su contenido en cada
    // frame de la transición — `RenderAnimatedOpacity.isRepaintBoundary` es
    // `true` para cualquier alpha > 0 (proxy_box.dart del SDK de Flutter).
    // Devolver el child sin envolver evita ese costo sin tocar cómo se ve
    // la ruta saliente.
    if (animation.isCompleted) {
      return child;
    }

    final curved = CurvedAnimation(parent: animation, curve: AppMotion.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        // 0.02 (2% de alto) medía ~1.6% real a mitad de la animación —
        // unos pocos píxeles, invisibles: en la práctica la transición era
        // solo el fundido, y un fundido puro sin ningún desplazamiento se
        // lee como que el contenido "aparece de golpe" en vez de deslizarse.
        // 0.06 sigue siendo corto y sutil (nada rebota, nada se dispara),
        // pero ya es un desplazamiento que el ojo alcanza a percibir.
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
