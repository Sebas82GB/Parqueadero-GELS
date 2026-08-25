import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:parqueadero_app/core/utils/money.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  // El separador entre el número y el símbolo es un espacio de no separación
  // (U+00A0), no un espacio común: así lo produce NumberFormat para es_CO.
  const nbsp = ' ';

  test('formatea cero', () {
    expect(formatMoney(0), '0$nbsp\$');
  });

  test('formatea con separador de miles es_CO', () {
    expect(formatMoney(20000), '20.000$nbsp\$');
  });

  test('formatea un valor grande sin dividir ni convertir a decimal', () {
    expect(formatMoney(1000000), '1.000.000$nbsp\$');
  });
}
