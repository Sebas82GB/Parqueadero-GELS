import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/core/theme/app_motion.dart';
import 'package:parqueadero_app/core/widgets/loading_skeleton.dart';

void main() {
  Future<Duration> effectiveEn(WidgetTester tester, {required bool disableAnimations}) async {
    late Duration resultado;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Builder(
          builder: (context) {
            resultado = AppMotion.effective(context, AppMotion.fast);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return resultado;
  }

  testWidgets('movimiento reducido activo: devuelve Duration.zero', (tester) async {
    final duracion = await effectiveEn(tester, disableAnimations: true);

    expect(duracion, Duration.zero);
  });

  testWidgets('movimiento reducido inactivo: devuelve la duración pedida', (tester) async {
    final duracion = await effectiveEn(tester, disableAnimations: false);

    expect(duracion, AppMotion.fast);
  });

  testWidgets('LoadingSkeleton con movimiento reducido activo: se renderiza estático sin lanzar excepción', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: LoadingSkeleton(width: 100, height: 20),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LoadingSkeleton), findsOneWidget);
  });
}
