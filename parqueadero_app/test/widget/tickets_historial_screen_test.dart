import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/widgets/empty_state.dart';
import 'package:parqueadero_app/core/widgets/error_state.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/presentation/tickets_historial_screen.dart';

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockTicketRepository ticketRepository;

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
    registerFallbackValue(EstadoTicket.abierto);
  });

  setUp(() {
    ticketRepository = MockTicketRepository();
  });

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

  void stubListar({List<Ticket> data = const [], int total = 0}) {
    when(
      () => ticketRepository.listar(
        estado: any(named: 'estado'),
        placa: any(named: 'placa'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (invocation) async => TicketPageResult(
        data: data,
        page: invocation.namedArguments[#page] as int,
        perPage: 20,
        total: total,
      ),
    );
  }

  Future<GoRouter> pumpHistorialScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/tickets',
      routes: [
        GoRoute(path: '/tickets', builder: (context, state) => const TicketsHistorialScreen()),
        GoRoute(path: '/tickets/:id', builder: (context, state) => Scaffold(body: Text('DETALLE_${state.pathParameters['id']}'))),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ticketRepositoryProvider.overrideWithValue(ticketRepository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('vacío: sin tickets muestra el mensaje de vacío', (tester) async {
    stubListar();

    await pumpHistorialScreen(tester);

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('error: muestra el mensaje del backend con reintentar', (tester) async {
    when(
      () => ticketRepository.listar(
        estado: any(named: 'estado'),
        placa: any(named: 'placa'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'No hay conexión con el servidor.', statusCode: 0));

    await pumpHistorialScreen(tester);

    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets('con datos: tap en un ticket navega al detalle', (tester) async {
    stubListar(data: [ticket('t1')], total: 1);

    await pumpHistorialScreen(tester);
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(find.text('DETALLE_t1'), findsOneWidget);
  });

  testWidgets('con datos: muestra la lista y "Cargar más" cuando hayMas', (tester) async {
    stubListar(data: [ticket('t1')], total: 2);

    await pumpHistorialScreen(tester);

    expect(find.widgetWithText(ElevatedButton, 'Cargar más'), findsOneWidget);
  });

  testWidgets('cambiar el filtro de estado vuelve a pedir la página 1', (tester) async {
    stubListar(data: [ticket('t1')], total: 1);

    await pumpHistorialScreen(tester);
    await tester.tap(find.text('Todos los estados'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pagado').last);
    await tester.pumpAndSettle();

    verify(
      () => ticketRepository.listar(
        estado: EstadoTicket.pagado,
        placa: any(named: 'placa'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: any(named: 'perPage'),
      ),
    ).called(1);
  });
}
