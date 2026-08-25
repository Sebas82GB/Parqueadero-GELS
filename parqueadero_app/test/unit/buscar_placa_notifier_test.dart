import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/presentation/buscar_placa_notifier.dart';

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockTicketRepository ticketRepository;
  late ProviderContainer container;

  Ticket ticket({required EstadoTicket estado, DateTime? horaSalida, int? valorTotal}) => Ticket(
    id: 't1',
    codigo: 'T-260101-ABC123',
    vehiculoId: 'veh1',
    celdaId: 'cel1',
    horaEntrada: DateTime.utc(2026, 1, 1, 13),
    horaSalida: horaSalida,
    tarifaId: 'tar1',
    valorTotal: valorTotal,
    estado: estado,
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

  test('encontrado abierto: guarda el ticket con estado abierto, sin fijar filtro de estado', () async {
    when(
      () => ticketRepository.listar(placa: 'ABC123', perPage: 1),
    ).thenAnswer((_) async => TicketPageResult(data: [ticket(estado: EstadoTicket.abierto)], page: 1, perPage: 1, total: 1));

    await container.read(buscarPlacaNotifierProvider.notifier).buscar('ABC123');

    final state = container.read(buscarPlacaNotifierProvider);
    expect(state.buscado, isTrue);
    expect(state.ticket?.estado, EstadoTicket.abierto);
    expect(state.errorMessage, isNull);
  });

  test('encontrado cerrado: guarda el ticket con su valorTotal y horaSalida', () async {
    when(() => ticketRepository.listar(placa: 'ABC123', perPage: 1)).thenAnswer(
      (_) async => TicketPageResult(
        data: [ticket(estado: EstadoTicket.pagado, horaSalida: DateTime.utc(2026, 1, 1, 15), valorTotal: 9000)],
        page: 1,
        perPage: 1,
        total: 1,
      ),
    );

    await container.read(buscarPlacaNotifierProvider.notifier).buscar('ABC123');

    final state = container.read(buscarPlacaNotifierProvider);
    expect(state.ticket?.estado, EstadoTicket.pagado);
    expect(state.ticket?.valorTotal, 9000);
    expect(state.ticket?.horaSalida, DateTime.utc(2026, 1, 1, 15));
  });

  test('no encontrado: buscado en true, ticket null, sin error', () async {
    when(
      () => ticketRepository.listar(placa: 'XYZ999', perPage: 1),
    ).thenAnswer((_) async => const TicketPageResult(data: [], page: 1, perPage: 1, total: 0));

    await container.read(buscarPlacaNotifierProvider.notifier).buscar('XYZ999');

    final state = container.read(buscarPlacaNotifierProvider);
    expect(state.buscado, isTrue);
    expect(state.ticket, isNull);
    expect(state.errorMessage, isNull);
  });

  test('error de backend: expone el mensaje y no marca buscado', () async {
    when(() => ticketRepository.listar(placa: 'ABC123', perPage: 1)).thenThrow(
      const ApiException(code: 'UNKNOWN', message: 'Ha ocurrido un error', statusCode: 500),
    );

    await container.read(buscarPlacaNotifierProvider.notifier).buscar('ABC123');

    final state = container.read(buscarPlacaNotifierProvider);
    expect(state.errorMessage, 'Ha ocurrido un error');
    expect(state.buscado, isFalse);
  });
}
