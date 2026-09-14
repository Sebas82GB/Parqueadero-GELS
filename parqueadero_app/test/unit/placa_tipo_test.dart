import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/core/domain/tipo_vehiculo.dart';
import 'package:parqueadero_app/core/utils/placa_tipo.dart';

void main() {
  group('tipoVehiculoDePlaca', () {
    test('3 letras + 3 números -> carro', () {
      expect(tipoVehiculoDePlaca('ABC123'), TipoVehiculo.carro);
    });

    test('3 letras + 2 números + 1 letra -> moto (formato actual)', () {
      expect(tipoVehiculoDePlaca('ABC12D'), TipoVehiculo.moto);
    });

    test('3 letras + 2 números -> moto (formato antiguo)', () {
      expect(tipoVehiculoDePlaca('ABC12'), TipoVehiculo.moto);
    });

    test('caso real del usuario: AAA1234 no coincide con ningún formato', () {
      expect(tipoVehiculoDePlaca('AAA1234'), isNull);
    });

    test('placa demasiado corta -> null', () {
      expect(tipoVehiculoDePlaca('AB'), isNull);
    });

    test('solo letras, sin números -> null', () {
      expect(tipoVehiculoDePlaca('ABCDEF'), isNull);
    });

    test('espera la placa ya normalizada en mayúsculas: minúsculas no coinciden', () {
      expect(tipoVehiculoDePlaca('abc123'), isNull);
    });
  });
}
