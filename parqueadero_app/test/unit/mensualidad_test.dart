import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/features/mensualidades/domain/mensualidad.dart';

void main() {
  Mensualidad mensualidad({
    DateTime? fechaFin,
    EstadoPagoMensualidad estadoPago = EstadoPagoMensualidad.noPagada,
  }) => Mensualidad(
    id: 'm1',
    vehiculoId: 'veh1',
    celdaId: null,
    fechaInicio: DateTime.utc(2026, 1, 1),
    fechaFin: fechaFin ?? DateTime.utc(2026, 2, 1),
    valorMensualidad: 150000,
    estadoPago: estadoPago,
    fechaPago: null,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  group('vigencia', () {
    final ahora = DateTime.utc(2026, 1, 15);

    test('CANCELADA tiene prioridad absoluta aunque esté vencida por fecha', () {
      final m = mensualidad(fechaFin: DateTime.utc(2025, 1, 1), estadoPago: EstadoPagoMensualidad.cancelada);

      expect(m.vigencia(ahora: ahora), VigenciaMensualidad.cancelada);
    });

    test('fechaFin en el pasado: VENCIDA', () {
      final m = mensualidad(fechaFin: ahora.subtract(const Duration(seconds: 1)));

      expect(m.vigencia(ahora: ahora), VigenciaMensualidad.vencida);
    });

    test('fechaFin justo en el borde de 7 días: todavía VIGENTE (no POR_VENCER)', () {
      final m = mensualidad(fechaFin: ahora.add(const Duration(days: 7)));

      expect(m.vigencia(ahora: ahora, diasPorVencer: 7), VigenciaMensualidad.vigente);
    });

    test('un segundo antes del borde de 7 días: POR_VENCER', () {
      final m = mensualidad(fechaFin: ahora.add(const Duration(days: 7)).subtract(const Duration(seconds: 1)));

      expect(m.vigencia(ahora: ahora, diasPorVencer: 7), VigenciaMensualidad.porVencer);
    });

    test('fechaFin muy en el futuro: VIGENTE', () {
      final m = mensualidad(fechaFin: ahora.add(const Duration(days: 60)));

      expect(m.vigencia(ahora: ahora), VigenciaMensualidad.vigente);
    });

    test('diasPorVencer personalizado cambia el borde', () {
      final m = mensualidad(fechaFin: ahora.add(const Duration(days: 3)));

      expect(m.vigencia(ahora: ahora, diasPorVencer: 2), VigenciaMensualidad.vigente);
      expect(m.vigencia(ahora: ahora, diasPorVencer: 5), VigenciaMensualidad.porVencer);
    });
  });

  group('VigenciaMensualidad.toBackend', () {
    test('mapea los tres valores válidos del filtro del backend', () {
      expect(VigenciaMensualidad.vigente.toBackend(), 'VIGENTE');
      expect(VigenciaMensualidad.porVencer.toBackend(), 'POR_VENCER');
      expect(VigenciaMensualidad.vencida.toBackend(), 'VENCIDA');
    });

    test('cancelada no es un valor válido del filtro: lanza UnsupportedError', () {
      expect(() => VigenciaMensualidad.cancelada.toBackend(), throwsUnsupportedError);
    });
  });
}
