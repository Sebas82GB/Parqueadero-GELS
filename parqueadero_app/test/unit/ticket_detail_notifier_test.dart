import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/presentation/ticket_detail_notifier.dart';

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

  void mantenerVivo() => container.listen(ticketDetailNotifierProvider('t1'), (_, _) {});

  test('éxito: carga el ticket', () async {
    when(() => ticketRepository.obtenerPorId('t1')).thenAnswer((_) async => ticket());

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(ticketDetailNotifierProvider('t1'));
    expect(state.isLoading, isFalse);
    expect(state.ticket?.codigo, 'T-260101-ABC123');
  });

  test('404: expone el mensaje del backend', () async {
    when(() => ticketRepository.obtenerPorId('t1')).thenThrow(
      const ApiException(code: 'TICKET_NO_ENCONTRADO', message: 'Ticket no encontrado', statusCode: 404),
    );

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(ticketDetailNotifierProvider('t1'));
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, 'Ticket no encontrado');
    expect(state.ticket, isNull);
  });
}
