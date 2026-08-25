import 'package:flutter_test/flutter_test.dart';
import 'package:parqueadero_app/core/utils/elapsed_time.dart';

void main() {
  test('menos de una hora: solo minutos', () {
    expect(formatElapsed(const Duration(minutes: 45)), '45min');
  });

  test('una hora o más: horas y minutos', () {
    expect(formatElapsed(const Duration(hours: 1, minutes: 30)), '1h 30min');
  });

  test('cero: 0min', () {
    expect(formatElapsed(Duration.zero), '0min');
  });

  test('horas exactas: minutos en cero', () {
    expect(formatElapsed(const Duration(hours: 2)), '2h 0min');
  });
}
