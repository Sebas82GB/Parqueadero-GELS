import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/features/turnos/domain/arqueo_turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno.dart';
import 'package:parqueadero_app/features/turnos/presentation/widgets/turno_kpis_view.dart';

void main() {
  // `cierre` no tiene valor por defecto propio: cada test lo indica explícito
  // (o lo deja en `null` para un turno abierto) para no arrastrar el defecto
  // de un turno cerrado en los casos que prueban justamente lo contrario.
  ArqueoTurno arqueo({
    EstadoTurno estado = EstadoTurno.cerrado,
    DateTime? apertura,
    required DateTime? cierre,
    int baseInicial = 50000,
    TotalesPorMetodo totalesPorMetodo = const TotalesPorMetodo(efectivo: 15000, tarjeta: 20000, transferencia: 0),
    int totalRecaudado = 35000,
    int ticketsCerrados = 4,
    int efectivoEsperado = 65000,
    int? efectivoContado = 65000,
    int? diferencia = 0,
  }) => ArqueoTurno(
    turnoId: 'tur1',
    operadorId: 'op1',
    estado: estado,
    apertura: apertura ?? DateTime.utc(2026, 1, 1, 6),
    cierre: cierre,
    baseInicial: baseInicial,
    totalesPorMetodo: totalesPorMetodo,
    totalRecaudado: totalRecaudado,
    ticketsCerrados: ticketsCerrados,
    efectivoEsperado: efectivoEsperado,
    efectivoContado: efectivoContado,
    diferencia: diferencia,
  );

  group('caso normal: cifras verificables a mano', () {
    // Turno de 8h (06:00 a 14:00), $35.000 recaudados, 4 tickets, $15.000 en
    // efectivo de un total de $35.000, cuadre exacto.
    final cierre = DateTime.utc(2026, 1, 1, 14);

    test('duración, recaudo/hora, tickets/hora y ticket promedio', () {
      final kpis = TurnoKpis.calcular(arqueo(cierre: cierre), cierre);

      expect(kpis.duracion, const Duration(hours: 8));
      expect(kpis.recaudoPorHora, 4375); // 35000 / 8 = 4375.0
      expect(kpis.ticketsPorHora, 0.5); // 4 / 8
      expect(kpis.ticketPromedio, 8750); // 35000 / 4 = 8750.0
    });

    test('composición del recaudo por método', () {
      final kpis = TurnoKpis.calcular(arqueo(cierre: cierre), cierre);

      expect(kpis.porcentajeEfectivo, closeTo(42.857, 0.001)); // 15000/35000*100
      expect(kpis.porcentajeTarjeta, closeTo(57.143, 0.001)); // 20000/35000*100
      expect(kpis.porcentajeTransferencia, 0.0);
    });

    test('descuadre como % del efectivo esperado, con cuadre exacto', () {
      final kpis = TurnoKpis.calcular(arqueo(cierre: cierre), cierre);

      expect(kpis.descuadrePorcentaje, 0.0); // 0 / 65000 * 100
    });

    test('efectivo en caja: efectivoEsperado - baseInicial', () {
      final kpis = TurnoKpis.calcular(arqueo(cierre: cierre), cierre);

      expect(kpis.efectivoEnCaja, 15000); // 65000 - 50000
    });

    test('descuadre con sobrante: diferencia positiva da porcentaje positivo', () {
      final kpis = TurnoKpis.calcular(
        arqueo(cierre: cierre, efectivoContado: 70000, diferencia: 5000),
        cierre,
      );

      expect(kpis.descuadrePorcentaje, closeTo(7.692, 0.001)); // 5000/65000*100
    });

    test('descuadre con faltante: diferencia negativa da porcentaje negativo', () {
      final kpis = TurnoKpis.calcular(
        arqueo(cierre: cierre, efectivoContado: 60000, diferencia: -5000),
        cierre,
      );

      expect(kpis.descuadrePorcentaje, closeTo(-7.692, 0.001)); // -5000/65000*100
    });
  });

  group('división por cero protegida: nunca NaN/Infinity, siempre null', () {
    final cierre = DateTime.utc(2026, 1, 1, 14);

    test('turno sin tickets cerrados: ticketPromedio es null', () {
      final kpis = TurnoKpis.calcular(arqueo(cierre: cierre, ticketsCerrados: 0), cierre);

      expect(kpis.ticketPromedio, isNull);
      expect(kpis.ticketPromedio.toString(), isNot(contains('NaN')));
    });

    test('turno sin recaudo: los porcentajes de composición son null', () {
      final kpis = TurnoKpis.calcular(
        arqueo(
          cierre: cierre,
          totalRecaudado: 0,
          totalesPorMetodo: const TotalesPorMetodo(efectivo: 0, tarjeta: 0, transferencia: 0),
        ),
        cierre,
      );

      expect(kpis.porcentajeEfectivo, isNull);
      expect(kpis.porcentajeTarjeta, isNull);
      expect(kpis.porcentajeTransferencia, isNull);
    });

    test('turno recién abierto (0 segundos transcurridos): recaudo y tickets por hora son null', () {
      final apertura = DateTime.utc(2026, 1, 1, 6);
      final kpis = TurnoKpis.calcular(
        arqueo(estado: EstadoTurno.abierto, apertura: apertura, cierre: null),
        apertura, // ahora == apertura: horas == 0
      );

      expect(kpis.recaudoPorHora, isNull);
      expect(kpis.ticketsPorHora, isNull);
      expect(kpis.duracion, Duration.zero);
    });

    test('efectivoEsperado en 0: descuadrePorcentaje es null aunque haya diferencia', () {
      final kpis = TurnoKpis.calcular(
        arqueo(cierre: cierre, efectivoEsperado: 0, efectivoContado: 0, diferencia: 0),
        cierre,
      );

      expect(kpis.descuadrePorcentaje, isNull);
    });
  });

  group('diferencia null: arqueo aún no contado', () {
    test('descuadrePorcentaje es null sin importar efectivoEsperado', () {
      final kpis = TurnoKpis.calcular(
        arqueo(estado: EstadoTurno.abierto, cierre: null, efectivoContado: null, diferencia: null),
        DateTime.utc(2026, 1, 1, 14),
      );

      expect(kpis.descuadrePorcentaje, isNull);
    });
  });

  group('turno abierto sin cierre', () {
    test('duración se calcula contra "ahora", no contra un cierre inexistente', () {
      final apertura = DateTime.utc(2026, 1, 1, 6);
      final ahora = DateTime.utc(2026, 1, 1, 9, 30);
      final kpis = TurnoKpis.calcular(
        arqueo(estado: EstadoTurno.abierto, apertura: apertura, cierre: null, efectivoContado: null, diferencia: null),
        ahora,
      );

      expect(kpis.duracion, const Duration(hours: 3, minutes: 30));
      expect(kpis.tiempoEsperandoArqueo, isNull); // no está cerradoPendienteArqueo
    });
  });

  group('tiempo esperando arqueo', () {
    test('solo se calcula si el estado es cerradoPendienteArqueo y hay cierre', () {
      final cierre = DateTime.utc(2026, 1, 1, 14);
      final ahora = DateTime.utc(2026, 1, 1, 15, 15);
      final kpis = TurnoKpis.calcular(
        arqueo(estado: EstadoTurno.cerradoPendienteArqueo, cierre: cierre, efectivoContado: null, diferencia: null),
        ahora,
      );

      expect(kpis.tiempoEsperandoArqueo, const Duration(hours: 1, minutes: 15));
    });

    test('turno cerrado (no pendiente): tiempoEsperandoArqueo es null', () {
      final kpis = TurnoKpis.calcular(
        arqueo(estado: EstadoTurno.cerrado, cierre: DateTime.utc(2026, 1, 1, 14)),
        DateTime.utc(2026, 1, 1, 20),
      );

      expect(kpis.tiempoEsperandoArqueo, isNull);
    });
  });
}
