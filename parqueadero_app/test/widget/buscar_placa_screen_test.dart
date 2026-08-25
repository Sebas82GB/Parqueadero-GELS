import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/presentation/buscar_placa_screen.dart';

class MockTicketRepository extends Mock implements TicketRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockTicketRepository ticketRepository;
  late MockAuthRepository authRepository;

  Usuario usuario(RolUsuario rol) => Usuario(
    id: 'u1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: rol,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Ticket ticketAbierto() => Ticket(
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
    celda: Celda(
      id: 'cel1',
      codigo: 'A-01',
      zona: 'Zona A',
      tipoPermitido: TipoVehiculo.carro,
      estado: EstadoCelda.ocupada,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  );

  Ticket ticketCerrado() => Ticket(
    id: 't2',
    codigo: 'T-260101-DEF456',
    vehiculoId: 'veh2',
    celdaId: 'cel1',
    horaEntrada: DateTime.utc(2026, 1, 1, 13),
    horaSalida: DateTime.utc(2026, 1, 1, 15),
    tarifaId: 'tar1',
    valorTotal: 9000,
    estado: EstadoTicket.pagado,
    operadorEntradaId: 'op1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    ticketRepository = MockTicketRepository();
    authRepository = MockAuthRepository();
  });

  Future<void> pumpBuscarScreen(WidgetTester tester, {required RolUsuario rol}) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(rol));
    final router = GoRouter(
      initialLocation: '/buscar',
      routes: [
        GoRoute(path: '/buscar', builder: (context, state) => const BuscarPlacaScreen()),
        GoRoute(
          path: '/tickets/:id/salida',
          builder: (context, state) => Scaffold(body: Text('SALIDA_${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/tickets/:id/recibo',
          builder: (context, state) => Scaffold(body: Text('RECIBO_${state.pathParameters['id']}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('adentro + OPERADOR: muestra celda, desde cuándo, cobro pendiente y botón de registrar salida', (
    tester,
  ) async {
    when(() => ticketRepository.listar(placa: 'ABC123', perPage: 1)).thenAnswer(
      (_) async => TicketPageResult(data: [ticketAbierto()], page: 1, perPage: 1, total: 1),
    );

    await pumpBuscarScreen(tester, rol: RolUsuario.operador);
    await tester.enterText(find.byType(TextFormField), 'abc123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Buscar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('A-01'), findsOneWidget);
    expect(find.text('Cobro: se calcula al registrar la salida.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Registrar salida'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.pumpAndSettle();

    expect(find.text('SALIDA_t1'), findsOneWidget);
  });

  testWidgets('adentro + ADMIN: no muestra el botón de registrar salida (403 para su rol)', (tester) async {
    when(() => ticketRepository.listar(placa: 'ABC123', perPage: 1)).thenAnswer(
      (_) async => TicketPageResult(data: [ticketAbierto()], page: 1, perPage: 1, total: 1),
    );

    await pumpBuscarScreen(tester, rol: RolUsuario.admin);
    await tester.enterText(find.byType(TextFormField), 'abc123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Buscar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('A-01'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Registrar salida'), findsNothing);
  });

  testWidgets('ya salió: muestra la hora de salida y el total cobrado, sin botón de registrar salida', (
    tester,
  ) async {
    when(() => ticketRepository.listar(placa: 'DEF456', perPage: 1)).thenAnswer(
      (_) async => TicketPageResult(data: [ticketCerrado()], page: 1, perPage: 1, total: 1),
    );

    await pumpBuscarScreen(tester, rol: RolUsuario.operador);
    await tester.enterText(find.byType(TextFormField), 'def456');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Buscar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Salida:'), findsOneWidget);
    expect(find.textContaining('9.000'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Registrar salida'), findsNothing);
  });

  testWidgets('nunca entró: mensaje distinto al de "ya salió"', (tester) async {
    when(
      () => ticketRepository.listar(placa: 'XYZ999', perPage: 1),
    ).thenAnswer((_) async => const TicketPageResult(data: [], page: 1, perPage: 1, total: 0));

    await pumpBuscarScreen(tester, rol: RolUsuario.operador);
    await tester.enterText(find.byType(TextFormField), 'xyz999');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Buscar'));
    await tester.pumpAndSettle();

    expect(find.text('No hay registros de esta placa en el parqueadero.'), findsOneWidget);
    expect(find.byType(BuscarPlacaScreen), findsOneWidget);
  });

  testWidgets('error de red: muestra el mensaje del backend', (tester) async {
    when(() => ticketRepository.listar(placa: 'ABC123', perPage: 1)).thenThrow(
      const NetworkException(message: 'No hay conexión con el servidor.', type: DioExceptionType.connectionError),
    );

    await pumpBuscarScreen(tester, rol: RolUsuario.operador);
    await tester.enterText(find.byType(TextFormField), 'abc123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Buscar'));
    await tester.pumpAndSettle();

    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
  });
}
