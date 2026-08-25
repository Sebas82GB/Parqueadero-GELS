import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/features/tickets/data/dtos/desglose_item_dto.dart';
import 'package:parqueadero_app/features/tickets/domain/desglose_item.dart';

void main() {
  test('null: lista vacía', () {
    expect(desgloseFromJson(null), isEmpty);
  });

  test('mensualidad: un único item con valor 0', () {
    final resultado = desgloseFromJson([
      {'tipo': 'MENSUALIDAD', 'valor': 0},
    ]);

    expect(resultado, [const DesgloseMensualidad()]);
  });

  test('manual: un único item con el valor digitado', () {
    final resultado = desgloseFromJson([
      {'tipo': 'MANUAL', 'valor': 15000},
    ]);

    expect(resultado, [const DesgloseManual(valor: 15000)]);
  });

  test('manual con valor null y motivo: preview de un vehículo OTRO', () {
    final resultado = desgloseFromJson([
      {'tipo': 'MANUAL', 'valor': null, 'motivo': 'El operador digita el valor al registrar la salida'},
    ]);

    expect(resultado, [
      const DesgloseManual(valor: null, motivo: 'El operador digita el valor al registrar la salida'),
    ]);
    expect((resultado.single as DesgloseManual).valor, isNull);
  });

  test('bloques: parsea día, bloque, horario, minutos, tipoCobro y valor', () {
    final resultado = desgloseFromJson([
      {
        'dia': 1,
        'bloqueNumero': 1,
        'inicio': '2026-01-01T13:00:00.000Z',
        'fin': '2026-01-01T17:00:00.000Z',
        'minutos': 240,
        'tipoCobro': 'PLENA',
        'valor': 20000,
      },
      {
        'dia': 1,
        'bloqueNumero': 2,
        'inicio': '2026-01-01T17:00:00.000Z',
        'fin': '2026-01-02T02:00:00.000Z',
        'minutos': 540,
        'tipoCobro': 'NOCTURNA',
        'valor': 16000,
      },
    ]);

    expect(resultado, [
      DesgloseBloque(
        dia: 1,
        bloqueNumero: 1,
        inicio: DateTime.parse('2026-01-01T13:00:00.000Z'),
        fin: DateTime.parse('2026-01-01T17:00:00.000Z'),
        minutos: 240,
        tipoCobro: TipoCobro.plena,
        valor: 20000,
      ),
      DesgloseBloque(
        dia: 1,
        bloqueNumero: 2,
        inicio: DateTime.parse('2026-01-01T17:00:00.000Z'),
        fin: DateTime.parse('2026-01-02T02:00:00.000Z'),
        minutos: 540,
        tipoCobro: TipoCobro.nocturna,
        valor: 16000,
      ),
    ]);
  });

  test('bloque PARCIAL: se distingue de PLENA/NOCTURNA', () {
    final resultado = desgloseFromJson([
      {
        'dia': 1,
        'bloqueNumero': 1,
        'inicio': '2026-01-01T13:00:00.000Z',
        'fin': '2026-01-01T14:30:00.000Z',
        'minutos': 90,
        'tipoCobro': 'PARCIAL',
        'valor': 9000,
      },
    ]);

    expect((resultado.single as DesgloseBloque).tipoCobro, TipoCobro.parcial);
  });

  test('tipo desconocido en la variante {tipo,valor}: lanza FormatException', () {
    expect(
      () => desgloseFromJson([
        {'tipo': 'DESCUENTO', 'valor': 500},
      ]),
      throwsFormatException,
    );
  });

  test('tipoCobro desconocido en un bloque: lanza FormatException', () {
    expect(
      () => desgloseFromJson([
        {
          'dia': 1,
          'bloqueNumero': 1,
          'inicio': '2026-01-01T13:00:00.000Z',
          'fin': '2026-01-01T14:00:00.000Z',
          'minutos': 60,
          'tipoCobro': 'EXPRESS',
          'valor': 1000,
        },
      ]),
      throwsFormatException,
    );
  });
}
