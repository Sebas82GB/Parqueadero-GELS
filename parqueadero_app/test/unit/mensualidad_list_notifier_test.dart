import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/mensualidades/data/mensualidad_repository_impl.dart';
import 'package:parqueadero_app/features/mensualidades/domain/mensualidad.dart';
import 'package:parqueadero_app/features/mensualidades/domain/mensualidad_repository.dart';
import 'package:parqueadero_app/features/mensualidades/presentation/mensualidad_list_notifier.dart';

class MockMensualidadRepository extends Mock implements MensualidadRepository {}

void main() {
  late MockMensualidadRepository mensualidadRepository;
  late ProviderContainer container;

  Mensualidad mensualidad(String id) => Mensualidad(
    id: id,
    vehiculoId: 'veh1',
    celdaId: null,
    fechaInicio: DateTime.utc(2026, 1, 1),
    fechaFin: DateTime.utc(2026, 2, 1),
    valorMensualidad: 150000,
    estadoPago: EstadoPagoMensualidad.noPagada,
    fechaPago: null,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    mensualidadRepository = MockMensualidadRepository();
    container = ProviderContainer(
      overrides: [mensualidadRepositoryProvider.overrideWithValue(mensualidadRepository)],
    );
    addTearDown(container.dispose);
  });

  void mantenerVivo() => container.listen(mensualidadListNotifierProvider, (_, _) {});

  test('carga inicial exitosa: pasa de isLoading a la lista', () async {
    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer(
      (_) async => MensualidadPageResult(data: [mensualidad('m1'), mensualidad('m2')], page: 1, perPage: 20, total: 2),
    );

    mantenerVivo();
    expect(container.read(mensualidadListNotifierProvider).isLoading, isTrue);

    await Future<void>.delayed(Duration.zero);

    final state = container.read(mensualidadListNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.mensualidades, hasLength(2));
    expect(state.hayMas, isFalse);
  });

  test('cargarMas: pide la página siguiente y concatena', () async {
    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => MensualidadPageResult(data: [mensualidad('m1')], page: 1, perPage: 20, total: 2));
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: 2,
        perPage: 20,
      ),
    ).thenAnswer((_) async => MensualidadPageResult(data: [mensualidad('m2')], page: 2, perPage: 20, total: 2));

    await container.read(mensualidadListNotifierProvider.notifier).cargarMas();

    final state = container.read(mensualidadListNotifierProvider);
    expect(state.mensualidades.map((m) => m.id), ['m1', 'm2']);
    expect(state.hayMas, isFalse);
  });

  test('cada filtro reinicia a página 1 con el query param correcto', () async {
    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => MensualidadPageResult(data: [mensualidad('m1')], page: 1, perPage: 20, total: 1));
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    container.read(mensualidadListNotifierProvider.notifier).setEstadoPagoFiltro(EstadoPagoMensualidad.pagada);
    await Future<void>.delayed(Duration.zero);

    verify(
      () => mensualidadRepository.listar(
        estadoPago: EstadoPagoMensualidad.pagada,
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: 1,
        perPage: 20,
      ),
    ).called(1);

    container.read(mensualidadListNotifierProvider.notifier).setVigenciaFiltro(VigenciaMensualidad.vencida);
    await Future<void>.delayed(Duration.zero);

    verify(
      () => mensualidadRepository.listar(
        estadoPago: EstadoPagoMensualidad.pagada,
        placa: any(named: 'placa'),
        vigencia: VigenciaMensualidad.vencida,
        page: 1,
        perPage: 20,
      ),
    ).called(1);

    container.read(mensualidadListNotifierProvider.notifier).setPlacaFiltro('ABC123');
    await Future<void>.delayed(Duration.zero);

    verify(
      () => mensualidadRepository.listar(
        estadoPago: EstadoPagoMensualidad.pagada,
        placa: 'ABC123',
        vigencia: VigenciaMensualidad.vencida,
        page: 1,
        perPage: 20,
      ),
    ).called(1);
  });

  test('error en cargarMas de fondo no borra la lista ya visible', () async {
    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => MensualidadPageResult(data: [mensualidad('m1')], page: 1, perPage: 20, total: 2));
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: 2,
        perPage: 20,
      ),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'falla de fondo', statusCode: 500));

    await container.read(mensualidadListNotifierProvider.notifier).cargarMas();

    final state = container.read(mensualidadListNotifierProvider);
    expect(state.mensualidades, hasLength(1));
    expect(state.errorMessage, isNull);
  });

  test('carga inicial con error: expone el mensaje y lista vacía', () async {
    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: 1,
        perPage: 20,
      ),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'Ha ocurrido un error', statusCode: 500));

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(mensualidadListNotifierProvider);
    expect(state.errorMessage, 'Ha ocurrido un error');
    expect(state.mensualidades, isEmpty);
  });

  test('reemplazarMensualidad actualiza solo la mensualidad con ese id', () async {
    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer(
      (_) async => MensualidadPageResult(data: [mensualidad('m1'), mensualidad('m2')], page: 1, perPage: 20, total: 2),
    );
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final cancelada = Mensualidad(
      id: 'm1',
      vehiculoId: 'veh1',
      celdaId: null,
      fechaInicio: DateTime.utc(2026, 1, 1),
      fechaFin: DateTime.utc(2026, 2, 1),
      valorMensualidad: 150000,
      estadoPago: EstadoPagoMensualidad.cancelada,
      fechaPago: null,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    container.read(mensualidadListNotifierProvider.notifier).reemplazarMensualidad(cancelada);

    final state = container.read(mensualidadListNotifierProvider);
    expect(state.mensualidades.firstWhere((m) => m.id == 'm1').estadoPago, EstadoPagoMensualidad.cancelada);
    expect(state.mensualidades.firstWhere((m) => m.id == 'm2').estadoPago, EstadoPagoMensualidad.noPagada);
  });
}
