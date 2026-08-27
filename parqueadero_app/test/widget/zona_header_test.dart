import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/core/theme/app_colors.dart';
import 'package:parqueadero_app/features/celdas/presentation/widgets/zona_header.dart';

void main() {
  Future<void> pumpZonaHeader(
    WidgetTester tester, {
    required int libres,
    required int ocupadas,
    required int mantenimiento,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZonaHeader(
            zona: 'Zona A',
            libres: libres,
            ocupadas: ocupadas,
            mantenimiento: mantenimiento,
            total: libres + ocupadas + mantenimiento,
          ),
        ),
      ),
    );
  }

  List<BoxDecoration> decoracionesDeSegmentos(WidgetTester tester) {
    return tester.widgetList<Container>(find.byType(Container)).map((c) => c.decoration).whereType<BoxDecoration>().toList();
  }

  // Regresión del hallazgo de la auditoría UX: la barra codificaba
  // ocupación con rojo/verde tipo semáforo, lo que rompe la regla de la
  // skill `diseno-parqueadero` de no comunicar estado por matiz. Ahora usa
  // el mismo lenguaje que la bahía pintada de las celdas individuales.
  testWidgets('la barra de ocupación usa los tokens de marca, no un semáforo rojo/verde', (tester) async {
    await pumpZonaHeader(tester, libres: 5, ocupadas: 3, mantenimiento: 2);

    final colores = decoracionesDeSegmentos(tester).map((d) => d.color).toList();

    expect(colores, containsAll(<Color?>[AppColors.concreto, AppColors.asfalto, AppColors.demarcacion]));
    // Los tonos de StatusStyle (semáforo success/danger/warning) no deben sobrevivir en la barra.
    expect(colores, isNot(contains(const Color(0xFF1B7F51))));
    expect(colores, isNot(contains(const Color(0xFFD0362D))));
    expect(colores, isNot(contains(const Color(0xFFA85D10))));
  });

  testWidgets('el segmento libre se lee vacío: relleno concreto con borde demarcacion', (tester) async {
    await pumpZonaHeader(tester, libres: 5, ocupadas: 3, mantenimiento: 0);

    final segmentoLibre = decoracionesDeSegmentos(
      tester,
    ).firstWhere((d) => d.color == AppColors.concreto);

    final border = segmentoLibre.border! as Border;
    expect(border.top.color, AppColors.demarcacion);
  });

  testWidgets('el segmento ocupado se lee lleno: relleno asfalto', (tester) async {
    await pumpZonaHeader(tester, libres: 5, ocupadas: 3, mantenimiento: 0);

    final segmentoOcupado = decoracionesDeSegmentos(tester).firstWhere((d) => d.color == AppColors.asfalto);

    expect(segmentoOcupado.color, AppColors.asfalto);
  });
}
