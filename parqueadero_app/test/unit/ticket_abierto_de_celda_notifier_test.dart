import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/presentation/ticket_abierto_de_celda_notifier.dart';

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockTicketRepository ticketRepository;
  late ProviderContainer container;

  Ticket ticket() => Ticket(
    id: 't1',
    codigo: 'T-260101-ABC123',
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

  test('encontrado: retorna el id del ticket abierto', () async {
    when(
      () => ticketRepository.listar(celdaId: 'cel1', estado: EstadoTicket.abierto, perPage: 1),
    ).thenAnswer((_) async => TicketPageResult(data: [ticket()], page: 1, perPage: 1, total: 1));

    final id = await container.read(ticketAbiertoDeCeldaNotifierProvider('cel1').notifier).buscar();

    expect(id, 't1');
  });

  test('no encontrado: retorna null sin error', () async {
    when(
      () => ticketRepository.listar(celdaId: 'cel1', estado: EstadoTicket.abierto, perPage: 1),
    ).thenAnswer((_) async => const TicketPageResult(data: [], page: 1, perPage: 1, total: 0));

    final id = await container.read(ticketAbiertoDeCeldaNotifierProvider('cel1').notifier).buscar();

    expect(id, isNull);
    expect(container.read(ticketAbiertoDeCeldaNotifierProvider('cel1')).errorMessage, isNull);
  });

  test('error de backend: expone el mensaje', () async {
    when(() => ticketRepository.listar(celdaId: 'cel1', estado: EstadoTicket.abierto, perPage: 1)).thenThrow(
      const ApiException(code: 'UNKNOWN', message: 'Ha ocurrido un error', statusCode: 500),
    );

    final id = await container.read(ticketAbiertoDeCeldaNotifierProvider('cel1').notifier).buscar();

    expect(id, isNull);
    expect(container.read(ticketAbiertoDeCeldaNotifierProvider('cel1')).errorMessage, 'Ha ocurrido un error');
  });
}
