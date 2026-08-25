import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/tarifas/data/tarifa_repository_impl.dart';
import 'package:parqueadero_app/features/tarifas/domain/tarifa.dart';
import 'package:parqueadero_app/features/tarifas/domain/tarifa_repository.dart';
import 'package:parqueadero_app/features/tarifas/presentation/nueva_tarifa_notifier.dart';
import 'package:parqueadero_app/features/tarifas/presentation/tarifa_list_notifier.dart';

class MockTarifaRepository extends Mock implements TarifaRepository {}

void main() {
  late MockTarifaRepository tarifaRepository;
  late ProviderContainer container;

  Tarifa tarifa() => Tarifa(
    id: 'tar1',
    tipoVehiculo: TipoVehiculo.carro,
    valorMinuto: 100,
    valorPlena: 8000,
    valorNocturna: 6000,
    valorMes: 150000,
    vigenteDesde: DateTime.utc(2026, 1, 1),
    vigenteHasta: null,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(TipoVehiculo.carro);
  });

  setUp(() {
    tarifaRepository = MockTarifaRepository();
    // tarifaListNotifierProvider arranca su propia carga al construirse, y
    // NuevaTarifaNotifier.crear() la refresca de nuevo tras crear.
    when(() => tarifaRepository.listarTodas()).thenAnswer((_) async => []);
    container = ProviderContainer(
      overrides: [tarifaRepositoryProvider.overrideWithValue(tarifaRepository)],
    );
    addTearDown(container.dispose);
    container.listen(tarifaListNotifierProvider, (_, _) {});
  });

  test('éxito: retorna la Tarifa creada y refresca TarifaListNotifier', () async {
    when(
      () => tarifaRepository.crear(
        tipoVehiculo: any(named: 'tipoVehiculo'),
        valorMinuto: any(named: 'valorMinuto'),
        valorPlena: any(named: 'valorPlena'),
        valorNocturna: any(named: 'valorNocturna'),
        valorMes: any(named: 'valorMes'),
      ),
    ).thenAnswer((_) async => tarifa());
    await Future<void>.delayed(Duration.zero);

    final resultado = await container
        .read(nuevaTarifaNotifierProvider.notifier)
        .crear(
          tipoVehiculo: TipoVehiculo.carro,
          valorMinuto: 100,
          valorPlena: 8000,
          valorNocturna: 6000,
          valorMes: 150000,
        );

    expect(resultado?.id, 'tar1');
    expect(container.read(nuevaTarifaNotifierProvider).errorMessage, isNull);
    verify(() => tarifaRepository.listarTodas()).called(greaterThanOrEqualTo(2));
  });

  test('400 validación: expone el mensaje del backend y retorna null', () async {
    when(
      () => tarifaRepository.crear(
        tipoVehiculo: any(named: 'tipoVehiculo'),
        valorMinuto: any(named: 'valorMinuto'),
        valorPlena: any(named: 'valorPlena'),
        valorNocturna: any(named: 'valorNocturna'),
        valorMes: any(named: 'valorMes'),
      ),
    ).thenThrow(const ApiException(code: 'VALIDATION_ERROR', message: 'valorMinuto debe ser un entero', statusCode: 400));

    final resultado = await container
        .read(nuevaTarifaNotifierProvider.notifier)
        .crear(
          tipoVehiculo: TipoVehiculo.carro,
          valorMinuto: -1,
          valorPlena: 8000,
          valorNocturna: 6000,
          valorMes: 150000,
        );

    expect(resultado, isNull);
    expect(container.read(nuevaTarifaNotifierProvider).errorMessage, 'valorMinuto debe ser un entero');
  });
}
