import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/core/utils/validators.dart';

void main() {
  group('placaValidator', () {
    test('placa vacía', () {
      expect(placaValidator(''), 'Ingresa la placa');
    });

    test('placa con menos de 3 caracteres', () {
      expect(placaValidator('AB'), 'La placa debe tener al menos 3 caracteres');
    });

    test('placa con más de 10 caracteres', () {
      expect(placaValidator('ABCDEFGHIJK'), 'La placa no puede superar 10 caracteres');
    });

    test('placa con símbolos no permitidos', () {
      expect(placaValidator('ABC!@#'), 'La placa solo admite letras, números y guiones');
    });

    test('placa válida', () {
      expect(placaValidator('ABC123'), isNull);
    });

    test('placa válida con guion', () {
      expect(placaValidator('AB-123'), isNull);
    });
  });

  group('placaConTipoValidator', () {
    test('acepta placa de carro', () {
      expect(placaConTipoValidator('ABC123'), isNull);
    });

    test('acepta placa de moto (formato actual)', () {
      expect(placaConTipoValidator('ABC12D'), isNull);
    });

    test('acepta placa de moto (formato antiguo)', () {
      expect(placaConTipoValidator('ABC12'), isNull);
    });

    test('rechaza AAA1234 (caso real del usuario) con mensaje que orienta a elegir "Otro"', () {
      expect(
        placaConTipoValidator('AAA1234'),
        'No reconocemos el formato. Un carro es ABC123 y una moto ABC12D. '
            'Si es otro vehículo, elige "Otro".',
      );
    });

    test('placa vacía: reporta el error de placaValidator, no el de formato', () {
      expect(placaConTipoValidator(''), 'Ingresa la placa');
    });
  });
}
