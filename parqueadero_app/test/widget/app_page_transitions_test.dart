import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/core/theme/app_motion.dart';
import 'package:parqueadero_app/core/theme/app_theme.dart';

void main() {
  group('AppPageTransitionsBuilder', () {
    const destino = Key('pantalla-destino');

    /// Monta la app con el tema real, empuja una segunda pantalla y devuelve
    /// la `PageRoute` viva que la está animando. La duración se mide sobre esa
    /// ruta — no sobre el token — porque es la ruta la que consulta el
    /// `pageTransitionsTheme`: si alguien quita el override, acá vuelven los
    /// 300 ms de la clase base del SDK y los tests fallan.
    ///
    /// Nunca `pumpAndSettle`: dejaría terminar la transición. Se bombea a
    /// tiempo cero, así que la ruta se atrapa todavía animándose. Hacen falta
    /// dos `pump()`: el primer frame solo aplica el cambio de historial del
    /// `Navigator` y el destino aún no está montado; recién en el segundo
    /// existe su elemento. Ninguno de los dos avanza el reloj.
    Future<ModalRoute<dynamic>> rutaEnTransicion(WidgetTester tester) async {
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          navigatorKey: navKey,
          home: const Scaffold(body: Text('origen')),
        ),
      );

      // Sin `await`: el push no se completa hasta que la ruta se cierra, y
      // acá justamente queremos inspeccionarla mientras sigue abierta.
      unawaited(
        navKey.currentState!.push<void>(
          MaterialPageRoute<void>(builder: (_) => const Scaffold(key: destino)),
        ),
      );
      await tester.pump();
      await tester.pump();

      return ModalRoute.of(tester.element(find.byKey(destino)))!;
    }

    testWidgets('transitionDuration devuelve AppMotion.medium (200 ms), no los 300 ms heredados de la clase base', (
      tester,
    ) async {
      final route = await rutaEnTransicion(tester);

      expect(route.transitionDuration, AppMotion.medium);
    });

    testWidgets('reverseTransitionDuration devuelve AppMotion.medium (200 ms)', (tester) async {
      final route = await rutaEnTransicion(tester);

      expect(route.reverseTransitionDuration, AppMotion.medium);
    });

    testWidgets('la duración de transición NO es la de la clase base de Flutter (300 ms)', (tester) async {
      final route = await rutaEnTransicion(tester);

      expect(route.transitionDuration, isNot(const Duration(milliseconds: 300)));
    });

    testWidgets('transitionDuration mide exactamente 200 ms (medición sobre la PageRoute real)', (tester) async {
      final route = await rutaEnTransicion(tester);

      expect(route.transitionDuration.inMilliseconds, 200);
    });
  });
}
