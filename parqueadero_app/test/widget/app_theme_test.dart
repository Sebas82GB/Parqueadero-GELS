import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/core/theme/app_theme.dart';

void main() {
  // Los diálogos de confirmación (registrar salida, cerrar turno, abrir
  // turno) arman sus acciones con TextButton/FilledButton. Sin un tamaño
  // mínimo tokenizado, Material los deja más chicos que el resto de botones
  // de la app — justo en el paso donde se cobra o se cierra caja.
  test('textButtonTheme: alto mínimo >= 48dp', () {
    final minimo = AppTheme.light.textButtonTheme.style!.minimumSize!.resolve({})!;

    expect(minimo.height, greaterThanOrEqualTo(48));
  });

  test('filledButtonTheme: alto mínimo >= 48dp', () {
    final minimo = AppTheme.light.filledButtonTheme.style!.minimumSize!.resolve({})!;

    expect(minimo.height, greaterThanOrEqualTo(48));
  });
}
