import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/features/celdas/presentation/celda_list_notifier.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/domain/vehiculo.dart';

class MockCeldaRepository extends Mock implements CeldaRepository {}

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockCeldaRepository celdaRepository;
  late MockTicketRepository ticketRepository;
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

  Vehiculo vehiculo({String placa = 'ABC123', TipoVehiculo tipo = TipoVehiculo.carro}) => Vehiculo(
    id: 'v1',
    placa: placa,
    tipo: tipo,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Ticket ticketAbierto({required String celdaId, required Vehiculo vehiculo}) => Ticket(
    id: 't-$celdaId',
    codigo: 'T-$celdaId',
    vehiculoId: vehiculo.id,
    celdaId: celdaId,
    horaEntrada: DateTime.utc(2026, 1, 1),
    tarifaId: 'tarifa1',
    estado: EstadoTicket.abierto,
    operadorEntradaId: 'op1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    vehiculo: vehiculo,
  );

  setUp(() {
    celdaRepository = MockCeldaRepository();
    ticketRepository = MockTicketRepository();
    // Salvo que un test lo sobrescriba, no hay tickets abiertos — así los
    // tests que no le interesa la placa no necesitan stubear esto.
    when(
      () => ticketRepository.listar(estado: any(named: 'estado'), perPage: any(named: 'perPage')),
    ).thenAnswer((_) async => const TicketPageResult(data: [], page: 1, perPage: 100, total: 0));
    container = ProviderContainer(
      overrides: [
        celdaRepositoryProvider.overrideWithValue(celdaRepository),
        ticketRepositoryProvider.overrideWithValue(ticketRepository),
      ],
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

  group('placa por celda', () {
    test('cruza los tickets abiertos con las celdas para armar el mapa de placas y tipos', () async {
      when(
        () => celdaRepository.listarTodas(),
      ).thenAnswer((_) async => [celda(id: 'c1', estado: EstadoCelda.ocupada)]);
      when(() => ticketRepository.listar(estado: EstadoTicket.abierto, perPage: 100)).thenAnswer(
        (_) async => TicketPageResult(
          data: [ticketAbierto(celdaId: 'c1', vehiculo: vehiculo(placa: 'XYZ999', tipo: TipoVehiculo.moto))],
          page: 1,
          perPage: 100,
          total: 1,
        ),
      );

      mantenerVivo();
      await Future<void>.delayed(Duration.zero);

      final info = container.read(celdaListNotifierProvider).ticketInfoPorCeldaId['c1'];
      expect(info?.placa, 'XYZ999');
      expect(info?.tipo, TipoVehiculo.moto);
    });

    test('un fallo al traer los tickets no tumba el refresco de celdas y conserva el mapa anterior', () async {
      when(
        () => celdaRepository.listarTodas(),
      ).thenAnswer((_) async => [celda(id: 'c1', estado: EstadoCelda.ocupada)]);
      when(() => ticketRepository.listar(estado: EstadoTicket.abierto, perPage: 100)).thenAnswer(
        (_) async => TicketPageResult(
          data: [ticketAbierto(celdaId: 'c1', vehiculo: vehiculo(placa: 'XYZ999'))],
          page: 1,
          perPage: 100,
          total: 1,
        ),
      );
      mantenerVivo();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(celdaListNotifierProvider).ticketInfoPorCeldaId['c1']?.placa, 'XYZ999');

      when(
        () => ticketRepository.listar(estado: EstadoTicket.abierto, perPage: 100),
      ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'falla de tickets', statusCode: 500));
      await container.read(celdaListNotifierProvider.notifier).refrescar();

      final state = container.read(celdaListNotifierProvider);
      expect(state.errorMessage, isNull, reason: 'la celda sí cargó, el fallo fue solo en tickets');
      expect(state.ticketInfoPorCeldaId['c1']?.placa, 'XYZ999');
    });
  });

  group('filtros', () {
    setUp(() async {
      when(() => celdaRepository.listarTodas()).thenAnswer(
        (_) async => [
          celda(id: 'c1', codigo: 'A-01', zona: 'Zona A', estado: EstadoCelda.libre, tipoPermitido: TipoVehiculo.carro),
          celda(id: 'c2', codigo: 'A-02', zona: 'Zona A', estado: EstadoCelda.ocupada, tipoPermitido: TipoVehiculo.carro),
          celda(id: 'c3', codigo: 'B-01', zona: 'Zona B', estado: EstadoCelda.libre, tipoPermitido: TipoVehiculo.moto),
        ],
      );
      when(() => ticketRepository.listar(estado: EstadoTicket.abierto, perPage: 100)).thenAnswer(
        (_) async => TicketPageResult(
          data: [ticketAbierto(celdaId: 'c2', vehiculo: vehiculo(placa: 'XYZ999'))],
          page: 1,
          perPage: 100,
          total: 1,
        ),
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

    test('setBusquedaFiltro matchea por código de celda', () {
      final notifier = container.read(celdaListNotifierProvider.notifier);
      notifier.setBusquedaFiltro('a-01');

      final state = container.read(celdaListNotifierProvider);
      expect(state.celdasFiltradas.map((c) => c.id), ['c1']);
    });

    test('setBusquedaFiltro matchea por la placa del ticket abierto de la celda', () {
      final notifier = container.read(celdaListNotifierProvider.notifier);
      notifier.setBusquedaFiltro('xyz');

      final state = container.read(celdaListNotifierProvider);
      expect(state.celdasFiltradas.map((c) => c.id), ['c2']);
    });

    test('limpiarFiltros vuelve a mostrar todo, incluida la búsqueda', () {
      final notifier = container.read(celdaListNotifierProvider.notifier);
      notifier.setZonaFiltro('Zona A');
      notifier.setBusquedaFiltro('xyz');
      notifier.limpiarFiltros();

      final state = container.read(celdaListNotifierProvider);
      expect(state.celdasFiltradas, hasLength(3));
      expect(state.zonaFiltro, isNull);
      expect(state.busquedaFiltro, isNull);
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
