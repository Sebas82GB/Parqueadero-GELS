import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/tarifas/data/tarifa_repository_impl.dart';
import 'package:parqueadero_app/features/tarifas/domain/tarifa.dart';
import 'package:parqueadero_app/features/tarifas/domain/tarifa_repository.dart';
import 'package:parqueadero_app/features/tarifas/presentation/tarifa_list_notifier.dart';

class MockTarifaRepository extends Mock implements TarifaRepository {}

void main() {
  late MockTarifaRepository tarifaRepository;
  late ProviderContainer container;

  Tarifa tarifa({
    String id = 'tar1',
    TipoVehiculo tipo = TipoVehiculo.carro,
    DateTime? vigenteDesde,
    DateTime? vigenteHasta,
  }) => Tarifa(
    id: id,
    tipoVehiculo: tipo,
    valorMinuto: 100,
    valorPlena: 8000,
    valorNocturna: 6000,
    valorMes: 150000,
    vigenteDesde: vigenteDesde ?? DateTime.utc(2026, 1, 1),
    vigenteHasta: vigenteHasta,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    tarifaRepository = MockTarifaRepository();
    container = ProviderContainer(
      overrides: [tarifaRepositoryProvider.overrideWithValue(tarifaRepository)],
    );
    addTearDown(container.dispose);
  });

  void mantenerVivo() => container.listen(tarifaListNotifierProvider, (_, _) {});

  test('carga inicial exitosa: pasa de isLoading a la lista completa', () async {
    when(() => tarifaRepository.listarTodas()).thenAnswer((_) async => [tarifa(id: 't1'), tarifa(id: 't2')]);

    mantenerVivo();
    expect(container.read(tarifaListNotifierProvider).isLoading, isTrue);

    await Future<void>.delayed(Duration.zero);

    final state = container.read(tarifaListNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.tarifas, hasLength(2));
  });

  test('carga inicial con error: expone el mensaje del backend', () async {
    when(
      () => tarifaRepository.listarTodas(),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'Ha ocurrido un error', statusCode: 500));

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(tarifaListNotifierProvider);
    expect(state.errorMessage, 'Ha ocurrido un error');
    expect(state.tarifas, isEmpty);
  });

  test('refrescar() con datos previos: un fallo de fondo no borra la lista ni muestra error', () async {
    when(() => tarifaRepository.listarTodas()).thenAnswer((_) async => [tarifa()]);
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(tarifaListNotifierProvider).tarifas, hasLength(1));

    when(
      () => tarifaRepository.listarTodas(),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'falla de fondo', statusCode: 500));
    await container.read(tarifaListNotifierProvider.notifier).refrescar();

    final state = container.read(tarifaListNotifierProvider);
    expect(state.tarifas, hasLength(1));
    expect(state.errorMessage, isNull);
  });

  group('tarifasFiltradasPorTipo', () {
    setUp(() async {
      when(() => tarifaRepository.listarTodas()).thenAnswer(
        (_) async => [
          tarifa(id: 'carro-vieja', tipo: TipoVehiculo.carro, vigenteDesde: DateTime.utc(2025, 1, 1),
              vigenteHasta: DateTime.utc(2026, 1, 1)),
          tarifa(id: 'carro-vigente', tipo: TipoVehiculo.carro, vigenteDesde: DateTime.utc(2026, 1, 1)),
          tarifa(id: 'moto-vigente', tipo: TipoVehiculo.moto, vigenteDesde: DateTime.utc(2026, 1, 1)),
        ],
      );
      mantenerVivo();
      await Future<void>.delayed(Duration.zero);
    });

    test('agrupa por tipo en orden de TipoVehiculo.values, vigenteDesde desc', () {
      final grupos = container.read(tarifaListNotifierProvider).tarifasFiltradasPorTipo;

      expect(grupos.keys.toList(), [TipoVehiculo.carro, TipoVehiculo.moto]);
      expect(grupos[TipoVehiculo.carro]!.map((t) => t.id), ['carro-vigente', 'carro-vieja']);
      expect(grupos[TipoVehiculo.moto]!.map((t) => t.id), ['moto-vigente']);
    });

    test('setTipoFiltro restringe el mapa a un solo tipo', () {
      container.read(tarifaListNotifierProvider.notifier).setTipoFiltro(TipoVehiculo.moto);

      final grupos = container.read(tarifaListNotifierProvider).tarifasFiltradasPorTipo;
      expect(grupos.keys, [TipoVehiculo.moto]);
    });

    test('un tipo sin tarifas no aparece en el mapa (bicicleta y otro)', () {
      final grupos = container.read(tarifaListNotifierProvider).tarifasFiltradasPorTipo;

      expect(grupos.containsKey(TipoVehiculo.bicicleta), isFalse);
      expect(grupos.containsKey(TipoVehiculo.otro), isFalse);
    });
  });
}
