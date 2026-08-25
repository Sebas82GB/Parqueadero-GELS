import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/domain/tipo_vehiculo.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/tarifas/data/tarifa_repository_impl.dart';
import 'package:parqueadero_app/features/tarifas/domain/tarifa_repository.dart';
import 'package:parqueadero_app/features/tarifas/presentation/tarifa_simulacion_notifier.dart';

class MockTarifaRepository extends Mock implements TarifaRepository {}

void main() {
  late MockTarifaRepository tarifaRepository;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(TipoVehiculo.carro));

  setUp(() {
    tarifaRepository = MockTarifaRepository();
    container = ProviderContainer(
      overrides: [tarifaRepositoryProvider.overrideWithValue(tarifaRepository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial: sin resultado', () {
    final state = container.read(tarifaSimulacionNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.tieneResultado, isFalse);
    expect(state.valorTotal, isNull);
  });

  test('simular con bloques: expone valorTotal', () async {
    when(
      () => tarifaRepository.simular(
        tipoVehiculo: TipoVehiculo.carro,
        valorMinuto: 100,
        valorPlena: 20000,
        valorNocturna: 16000,
        duracionMinutos: 120,
      ),
    ).thenAnswer((_) async => 20000);

    await container
        .read(tarifaSimulacionNotifierProvider.notifier)
        .simular(
          tipoVehiculo: TipoVehiculo.carro,
          valorMinuto: 100,
          valorPlena: 20000,
          valorNocturna: 16000,
          duracionMinutos: 120,
        );

    final state = container.read(tarifaSimulacionNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.tieneResultado, isTrue);
    expect(state.valorTotal, 20000);
  });

  test('simular con tipoVehiculo OTRO: tieneResultado true pero valorTotal null', () async {
    when(
      () => tarifaRepository.simular(
        tipoVehiculo: TipoVehiculo.otro,
        valorMinuto: 0,
        valorPlena: 0,
        valorNocturna: 0,
        duracionMinutos: 120,
      ),
    ).thenAnswer((_) async => null);

    await container
        .read(tarifaSimulacionNotifierProvider.notifier)
        .simular(
          tipoVehiculo: TipoVehiculo.otro,
          valorMinuto: 0,
          valorPlena: 0,
          valorNocturna: 0,
          duracionMinutos: 120,
        );

    final state = container.read(tarifaSimulacionNotifierProvider);
    expect(state.tieneResultado, isTrue);
    expect(state.valorTotal, isNull);
  });

  test('error del backend: expone el mensaje sin resultado', () async {
    when(
      () => tarifaRepository.simular(
        tipoVehiculo: any(named: 'tipoVehiculo'),
        valorMinuto: any(named: 'valorMinuto'),
        valorPlena: any(named: 'valorPlena'),
        valorNocturna: any(named: 'valorNocturna'),
        duracionMinutos: any(named: 'duracionMinutos'),
      ),
    ).thenThrow(const ApiException(code: 'VALIDATION_ERROR', message: 'Datos inválidos', statusCode: 400));

    await container
        .read(tarifaSimulacionNotifierProvider.notifier)
        .simular(
          tipoVehiculo: TipoVehiculo.carro,
          valorMinuto: 100,
          valorPlena: 20000,
          valorNocturna: 16000,
          duracionMinutos: 120,
        );

    final state = container.read(tarifaSimulacionNotifierProvider);
    expect(state.errorMessage, 'Datos inválidos');
    expect(state.tieneResultado, isFalse);
  });

  test('limpiar() vuelve al estado inicial', () async {
    when(
      () => tarifaRepository.simular(
        tipoVehiculo: any(named: 'tipoVehiculo'),
        valorMinuto: any(named: 'valorMinuto'),
        valorPlena: any(named: 'valorPlena'),
        valorNocturna: any(named: 'valorNocturna'),
        duracionMinutos: any(named: 'duracionMinutos'),
      ),
    ).thenAnswer((_) async => 20000);
    await container
        .read(tarifaSimulacionNotifierProvider.notifier)
        .simular(
          tipoVehiculo: TipoVehiculo.carro,
          valorMinuto: 100,
          valorPlena: 20000,
          valorNocturna: 16000,
          duracionMinutos: 120,
        );
    expect(container.read(tarifaSimulacionNotifierProvider).tieneResultado, isTrue);

    container.read(tarifaSimulacionNotifierProvider.notifier).limpiar();

    final state = container.read(tarifaSimulacionNotifierProvider);
    expect(state.tieneResultado, isFalse);
    expect(state.valorTotal, isNull);
  });
}
