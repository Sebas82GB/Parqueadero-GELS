import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/presentation/ticket_list_notifier.dart';

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockTicketRepository ticketRepository;
  late ProviderContainer container;

  Ticket ticket(String id) => Ticket(
    id: id,
    codigo: 'T-260101-$id',
    vehiculoId: 'veh1',
    celdaId: 'cel1',
    horaEntrada: DateTime.utc(2026, 1, 1, 13),
    tarifaId: 'tar1',
    estado: EstadoTicket.abierto,
    operadorEntradaId: 'op1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    ticketRepository = MockTicketRepository();
    container = ProviderContainer(
      overrides: [ticketRepositoryProvider.overrideWithValue(ticketRepository)],
    );
    addTearDown(container.dispose);
  });

  void mantenerVivo() => container.listen(ticketListNotifierProvider, (_, _) {});

  test('carga inicial exitosa: pasa de isLoading a la lista', () async {
    when(
      () => ticketRepository.listar(
        estado: any(named: 'estado'),
        placa: any(named: 'placa'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => TicketPageResult(data: [ticket('t1'), ticket('t2')], page: 1, perPage: 20, total: 2));

    mantenerVivo();
    expect(container.read(ticketListNotifierProvider).isLoading, isTrue);

    await Future<void>.delayed(Duration.zero);

    final state = container.read(ticketListNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.tickets, hasLength(2));
    expect(state.hayMas, isFalse);
  });

  test('cargarMas: pide la página siguiente y concatena', () async {
    when(
      () => ticketRepository.listar(
        estado: any(named: 'estado'),
        placa: any(named: 'placa'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => TicketPageResult(data: [ticket('t1')], page: 1, perPage: 20, total: 2));
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(ticketListNotifierProvider).hayMas, isTrue);

    when(
      () => ticketRepository.listar(
        estado: any(named: 'estado'),
        placa: any(named: 'placa'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 2,
        perPage: 20,
      ),
    ).thenAnswer((_) async => TicketPageResult(data: [ticket('t2')], page: 2, perPage: 20, total: 2));

    await container.read(ticketListNotifierProvider.notifier).cargarMas();

    final state = container.read(ticketListNotifierProvider);
    expect(state.tickets.map((t) => t.id), ['t1', 't2']);
    expect(state.hayMas, isFalse);
  });

  test('cambiar filtro de estado reinicia a página 1', () async {
    when(
      () => ticketRepository.listar(
        estado: any(named: 'estado'),
        placa: any(named: 'placa'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => TicketPageResult(data: [ticket('t1')], page: 1, perPage: 20, total: 1));
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    container.read(ticketListNotifierProvider.notifier).setEstadoFiltro(EstadoTicket.pagado);
    await Future<void>.delayed(Duration.zero);

    verify(
      () => ticketRepository.listar(
        estado: EstadoTicket.pagado,
        placa: any(named: 'placa'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: 20,
      ),
    ).called(1);
    expect(container.read(ticketListNotifierProvider).estadoFiltro, EstadoTicket.pagado);
  });

  test('error en cargarMas de fondo no borra la lista ya visible', () async {
    when(
      () => ticketRepository.listar(
        estado: any(named: 'estado'),
        placa: any(named: 'placa'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => TicketPageResult(data: [ticket('t1')], page: 1, perPage: 20, total: 2));
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    when(
      () => ticketRepository.listar(
        estado: any(named: 'estado'),
        placa: any(named: 'placa'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 2,
        perPage: 20,
      ),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'falla de fondo', statusCode: 500));

    await container.read(ticketListNotifierProvider.notifier).cargarMas();

    final state = container.read(ticketListNotifierProvider);
    expect(state.tickets, hasLength(1));
    expect(state.errorMessage, isNull);
  });

  test('carga inicial con error: expone el mensaje y lista vacía', () async {
    when(
      () => ticketRepository.listar(
        estado: any(named: 'estado'),
        placa: any(named: 'placa'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: 20,
      ),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'Ha ocurrido un error', statusCode: 500));

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(ticketListNotifierProvider);
    expect(state.errorMessage, 'Ha ocurrido un error');
    expect(state.tickets, isEmpty);
  });
}
