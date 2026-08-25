import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/features/celdas/presentation/celda_list_notifier.dart';

class MockCeldaRepository extends Mock implements CeldaRepository {}

void main() {
  late MockCeldaRepository celdaRepository;
  late ProviderContainer container;

  Celda celda({
    String id = 'c1',
    String codigo = 'A-01',
    String zona = 'Zona A',
    EstadoCelda estado = EstadoCelda.libre,
    TipoVehiculo tipoPermitido = TipoVehiculo.carro,
  }) => Celda(
    id: id,
    codigo: codigo,
    zona: zona,
    tipoPermitido: tipoPermitido,
    estado: estado,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    celdaRepository = MockCeldaRepository();
    container = ProviderContainer(
      overrides: [celdaRepositoryProvider.overrideWithValue(celdaRepository)],
    );
    addTearDown(container.dispose);
  });

  // celdaListNotifierProvider es autoDispose: un `container.read` suelto no
  // mantiene un listener, así que Riverpod lo desecha (y reconstruye desde
  // cero) apenas termina el turno de microtasks actual. `container.listen`
  // simula el `ref.watch` de una pantalla real y lo mantiene vivo durante
  // todo el test.
  void mantenerVivo() => container.listen(celdaListNotifierProvider, (_, _) {});

  test('carga inicial exitosa: pasa de isLoading a la lista completa', () async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celda(id: 'c1'), celda(id: 'c2')]);

    mantenerVivo();
    expect(container.read(celdaListNotifierProvider).isLoading, isTrue);

    await Future<void>.delayed(Duration.zero);

    final state = container.read(celdaListNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.celdas, hasLength(2));
  });

  test('carga inicial con error: expone el mensaje del backend', () async {
    when(
      () => celdaRepository.listarTodas(),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'Ha ocurrido un error', statusCode: 500));

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(celdaListNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, 'Ha ocurrido un error');
    expect(state.celdas, isEmpty);
  });

  test('refrescar() con datos previos: un fallo de fondo no borra el grid ni muestra error', () async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celda()]);
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(celdaListNotifierProvider).celdas, hasLength(1));

    when(
      () => celdaRepository.listarTodas(),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'falla de fondo', statusCode: 500));
    await container.read(celdaListNotifierProvider.notifier).refrescar();

    final state = container.read(celdaListNotifierProvider);
    expect(state.celdas, hasLength(1));
    expect(state.errorMessage, isNull);
  });

  group('filtros', () {
    setUp(() async {
      when(() => celdaRepository.listarTodas()).thenAnswer(
        (_) async => [
          celda(id: 'c1', zona: 'Zona A', estado: EstadoCelda.libre, tipoPermitido: TipoVehiculo.carro),
          celda(id: 'c2', zona: 'Zona A', estado: EstadoCelda.ocupada, tipoPermitido: TipoVehiculo.carro),
          celda(id: 'c3', zona: 'Zona B', estado: EstadoCelda.libre, tipoPermitido: TipoVehiculo.moto),
        ],
      );
      mantenerVivo();
      await Future<void>.delayed(Duration.zero);
    });

    test('setZonaFiltro filtra por zona, sin afectar los contadores por zona', () {
      final notifier = container.read(celdaListNotifierProvider.notifier);
      notifier.setZonaFiltro('Zona A');

      final state = container.read(celdaListNotifierProvider);
      expect(state.celdasFiltradas, hasLength(2));
      expect(state.totalLibres, 2); // sigue contando sobre TODA la lista
      expect(state.librresEnZona('Zona B'), 1);
    });

    test('setEstadoFiltro + setTipoFiltro combinan condiciones', () {
      final notifier = container.read(celdaListNotifierProvider.notifier);
      notifier.setEstadoFiltro(EstadoCelda.libre);
      notifier.setTipoFiltro(TipoVehiculo.carro);

      final state = container.read(celdaListNotifierProvider);
      expect(state.celdasFiltradas.map((c) => c.id), ['c1']);
    });

    test('limpiarFiltros vuelve a mostrar todo', () {
      final notifier = container.read(celdaListNotifierProvider.notifier);
      notifier.setZonaFiltro('Zona A');
      notifier.limpiarFiltros();

      final state = container.read(celdaListNotifierProvider);
      expect(state.celdasFiltradas, hasLength(3));
      expect(state.zonaFiltro, isNull);
    });

    test('celdasFiltradasPorZona agrupa y omite zonas sin resultados tras filtrar', () {
      final notifier = container.read(celdaListNotifierProvider.notifier);
      notifier.setEstadoFiltro(EstadoCelda.ocupada);

      final grupos = container.read(celdaListNotifierProvider).celdasFiltradasPorZona;
      expect(grupos.keys, ['Zona A']);
      expect(grupos['Zona A']!.map((c) => c.id), ['c2']);
    });
  });

  test('reemplazarCelda actualiza solo la celda con ese id', () async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celda(id: 'c1'), celda(id: 'c2')]);
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final actualizada = celda(id: 'c1', estado: EstadoCelda.mantenimiento);
    container.read(celdaListNotifierProvider.notifier).reemplazarCelda(actualizada);

    final state = container.read(celdaListNotifierProvider);
    expect(state.celdas, hasLength(2));
    expect(state.celdas.firstWhere((c) => c.id == 'c1').estado, EstadoCelda.mantenimiento);
    expect(state.celdas.firstWhere((c) => c.id == 'c2').estado, EstadoCelda.libre);
  });

  test('el timer de 30s dispara un refresco automático sin interacción del usuario', () {
    fakeAsync((async) {
      when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celda()]);

      mantenerVivo();
      async.flushMicrotasks();
      verify(() => celdaRepository.listarTodas()).called(1);

      async.elapse(const Duration(seconds: 31));
      async.flushMicrotasks();
      verify(() => celdaRepository.listarTodas()).called(1);
    });
  });
}
