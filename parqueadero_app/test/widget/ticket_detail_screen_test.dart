import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/widgets/error_state.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/desglose_item.dart';
import 'package:parqueadero_app/features/tickets/domain/pago.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/domain/vehiculo.dart';
import 'package:parqueadero_app/features/tickets/presentation/ticket_detail_screen.dart';

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockTicketRepository ticketRepository;

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    ticketRepository = MockTicketRepository();
  });

  Vehiculo vehiculo() => Vehiculo(
    id: 'veh1',
    placa: 'ABC123',
    tipo: TipoVehiculo.carro,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Celda celda() => Celda(
    id: 'cel1',
    codigo: 'A-01',
    zona: 'Zona A',
    tipoPermitido: TipoVehiculo.carro,
    estado: EstadoCelda.ocupada,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Future<void> pumpDetailScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ticketRepositoryProvider.overrideWithValue(ticketRepository)],
        child: const MaterialApp(home: TicketDetailScreen(ticketId: 't1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ticket ABIERTO: muestra el mensaje sin cobro registrado, sin desglose', (tester) async {
    when(() => ticketRepository.obtenerPorId('t1')).thenAnswer(
      (_) async => Ticket(
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
        vehiculo: vehiculo(),
        celda: celda(),
      ),
    );

    await pumpDetailScreen(tester);

    expect(find.text('Ticket aún abierto, sin cobro registrado.'), findsOneWidget);
    expect(find.text('Total'), findsNothing);
  });

  testWidgets('ticket PAGADO con desglose de bloques: muestra el detalle y el pago', (tester) async {
    when(() => ticketRepository.obtenerPorId('t1')).thenAnswer(
      (_) async => Ticket(
        id: 't1',
        codigo: 'T-260101-ABC123',
        vehiculoId: 'veh1',
        celdaId: 'cel1',
        horaEntrada: DateTime.utc(2026, 1, 1, 13),
        horaSalida: DateTime.utc(2026, 1, 1, 14, 30),
        tarifaId: 'tar1',
        valorTotal: 9000,
        desglose: [
          DesgloseBloque(
            dia: 1,
            bloqueNumero: 1,
            inicio: DateTime.utc(2026, 1, 1, 13),
            fin: DateTime.utc(2026, 1, 1, 14, 30),
            minutos: 90,
            tipoCobro: TipoCobro.parcial,
            valor: 9000,
          ),
        ],
        estado: EstadoTicket.pagado,
        operadorEntradaId: 'op1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        vehiculo: vehiculo(),
        celda: celda(),
        pago: Pago(
          id: 'pago1',
          ticketId: 't1',
          monto: 9000,
          metodo: MetodoPago.efectivo,
          turnoId: 'tur1',
          fecha: DateTime.utc(2026, 1, 1, 14, 30),
          estado: EstadoPago.valido,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ),
    );

    await pumpDetailScreen(tester);

    expect(find.text('Total'), findsOneWidget);
    expect(find.textContaining('Efectivo'), findsOneWidget);
  });

  testWidgets('el chip de estado lleva el mismo tag de Hero que el listado', (tester) async {
    when(() => ticketRepository.obtenerPorId('t1')).thenAnswer(
      (_) async => Ticket(
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
        vehiculo: vehiculo(),
        celda: celda(),
      ),
    );

    await pumpDetailScreen(tester);

    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'ticket-estado-t1');
  });

  testWidgets('404: muestra el error con reintentar', (tester) async {
    when(() => ticketRepository.obtenerPorId('t1')).thenThrow(
      const ApiException(code: 'TICKET_NO_ENCONTRADO', message: 'Ticket no encontrado', statusCode: 404),
    );

    await pumpDetailScreen(tester);

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Ticket no encontrado'), findsOneWidget);
  });
}
