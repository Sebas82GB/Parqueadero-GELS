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

    expect(colores, containsAll(<Color?>[AppColors.blancoHueso, AppColors.asfaltoClaro, AppColors.amarilloPastel]));
    // Los tonos de StatusStyle (semáforo success/danger/warning) no deben
    // sobrevivir en la barra. Hex recalibrados para fondo oscuro en la
    // reforma "Asfalto y Demarcación" (2026-09-15): lo que se verifica sigue
    // siendo lo mismo — que un color de ESTADO no se cuele en la barra.
    expect(colores, isNot(contains(const Color(0xFF7FD1A0))));
    expect(colores, isNot(contains(const Color(0xFFE88B7D))));
    expect(colores, isNot(contains(const Color(0xFFE8B563))));
  });

  testWidgets('el segmento libre se lee vacío: relleno blancoHueso con borde amarilloPastel', (tester) async {
    await pumpZonaHeader(tester, libres: 5, ocupadas: 3, mantenimiento: 0);

    final segmentoLibre = decoracionesDeSegmentos(
      tester,
    ).firstWhere((d) => d.color == AppColors.blancoHueso);

    final border = segmentoLibre.border! as Border;
    expect(border.top.color, AppColors.amarilloPastel);
  });

  testWidgets('el segmento ocupado se lee lleno: relleno asfaltoClaro', (tester) async {
    await pumpZonaHeader(tester, libres: 5, ocupadas: 3, mantenimiento: 0);

    final segmentoOcupado = decoracionesDeSegmentos(tester).firstWhere((d) => d.color == AppColors.asfaltoClaro);

    expect(segmentoOcupado.color, AppColors.asfaltoClaro);
  });
}
