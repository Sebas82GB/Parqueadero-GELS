import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/tarifas/data/tarifa_repository_impl.dart';
import 'package:parqueadero_app/features/tarifas/domain/tarifa.dart';
import 'package:parqueadero_app/features/tarifas/domain/tarifa_repository.dart';
import 'package:parqueadero_app/features/tarifas/presentation/tarifa_accion_notifier.dart';
import 'package:parqueadero_app/features/tarifas/presentation/tarifa_list_notifier.dart';

class MockTarifaRepository extends Mock implements TarifaRepository {}

void main() {
  late MockTarifaRepository tarifaRepository;
  late ProviderContainer container;

  Tarifa tarifa({DateTime? vigenteHasta}) => Tarifa(
    id: 'tar1',
    tipoVehiculo: TipoVehiculo.carro,
    valorMinuto: 100,
    valorPlena: 8000,
    valorNocturna: 6000,
    valorMes: 150000,
    vigenteDesde: DateTime.utc(2026, 1, 1),
    vigenteHasta: vigenteHasta,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    tarifaRepository = MockTarifaRepository();
    when(() => tarifaRepository.listarTodas()).thenAnswer((_) async => [tarifa()]);
    container = ProviderContainer(
      overrides: [tarifaRepositoryProvider.overrideWithValue(tarifaRepository)],
    );
    addTearDown(container.dispose);
    container.listen(tarifaListNotifierProvider, (_, _) {});
    container.listen(tarifaAccionNotifierProvider('tar1'), (_, _) {});
  });

  test('cerrar exitoso: limpia el error y refresca TarifaListNotifier', () async {
    when(() => tarifaRepository.cerrar('tar1')).thenAnswer(
      (_) async => tarifa(vigenteHasta: DateTime.utc(2026, 2, 1)),
    );
    await Future<void>.delayed(Duration.zero);

    await container.read(tarifaAccionNotifierProvider('tar1').notifier).cerrar();

    final accionState = container.read(tarifaAccionNotifierProvider('tar1'));
    expect(accionState.isLoading, isFalse);
    expect(accionState.errorMessage, isNull);
    verify(() => tarifaRepository.listarTodas()).called(greaterThanOrEqualTo(2));
  });

  test('cerrar falla con 409 TARIFA_YA_CERRADA: expone el mensaje del backend', () async {
    when(() => tarifaRepository.cerrar('tar1')).thenThrow(
      const ApiException(code: 'TARIFA_YA_CERRADA', message: 'La tarifa ya está cerrada', statusCode: 409),
    );

    await container.read(tarifaAccionNotifierProvider('tar1').notifier).cerrar();

    final accionState = container.read(tarifaAccionNotifierProvider('tar1'));
    expect(accionState.errorMessage, 'La tarifa ya está cerrada');
  });

  test('cerrar falla con 404 TARIFA_NO_ENCONTRADA: expone el mensaje del backend', () async {
    when(() => tarifaRepository.cerrar('tar1')).thenThrow(
      const ApiException(code: 'TARIFA_NO_ENCONTRADA', message: 'Tarifa no encontrada', statusCode: 404),
    );

    await container.read(tarifaAccionNotifierProvider('tar1').notifier).cerrar();

    expect(container.read(tarifaAccionNotifierProvider('tar1')).errorMessage, 'Tarifa no encontrada');
  });
}
