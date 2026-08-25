import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/widgets/error_state.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/features/celdas/presentation/celda_detail_screen.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCeldaRepository extends Mock implements CeldaRepository {}

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockCeldaRepository celdaRepository;
  late MockTicketRepository ticketRepository;

  Usuario usuario(RolUsuario rol) => Usuario(
    id: 'u1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: rol,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Celda celda(EstadoCelda estado) => Celda(
    id: 'c1',
    codigo: 'A-01',
    zona: 'Zona A',
    tipoPermitido: TipoVehiculo.carro,
    estado: estado,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUpAll(() async {
    // formatBogota() usa DateFormat con locale 'es_CO'; en main() lo hace
    // initializeDateFormatting, que los widget tests nunca ejecutan.
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    authRepository = MockAuthRepository();
    celdaRepository = MockCeldaRepository();
    ticketRepository = MockTicketRepository();
  });

  Future<void> pumpDetailScreen(WidgetTester tester, {required RolUsuario rol, required EstadoCelda estado}) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(rol));
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celda(estado)]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
        ],
        child: const MaterialApp(home: CeldaDetailScreen(celdaId: 'c1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Solo la navegación de "Registrar salida" necesita un GoRouter real (usa
  // context.push), a diferencia del resto de los tests de este archivo.
  Future<void> pumpDetailScreenConRouter(WidgetTester tester, {required EstadoCelda estado}) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(RolUsuario.operador));
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celda(estado)]);
    final router = GoRouter(
      initialLocation: '/celdas/c1',
      routes: [
        GoRoute(path: '/celdas/:id', builder: (context, state) => const CeldaDetailScreen(celdaId: 'c1')),
        GoRoute(
          path: '/tickets/:id/salida',
          builder: (context, state) => Scaffold(body: Text('SALIDA_${state.pathParameters['id']}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('celdas con error: muestra ErrorState con el mensaje del backend, no "no encontrada"', (
    tester,
  ) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(RolUsuario.admin));
    when(
      () => celdaRepository.listarTodas(),
    ).thenThrow(const ApiException(code: 'INTERNAL_ERROR', message: 'Error de red', statusCode: 500));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
        ],
        child: const MaterialApp(home: CeldaDetailScreen(celdaId: 'c1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Error de red'), findsOneWidget);
    expect(find.text('Celda no encontrada.'), findsNothing);
  });

  testWidgets('celdas con error: tocar Reintentar vuelve a pedir el listado', (tester) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(RolUsuario.admin));
    when(
      () => celdaRepository.listarTodas(),
    ).thenThrow(const ApiException(code: 'INTERNAL_ERROR', message: 'Error de red', statusCode: 500));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
        ],
        child: const MaterialApp(home: CeldaDetailScreen(celdaId: 'c1')),
      ),
    );
    await tester.pumpAndSettle();

    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celda(EstadoCelda.libre)]);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('A-01'), findsOneWidget);
  });

  testWidgets('ADMIN + LIBRE: muestra el botón de poner en mantenimiento', (tester) async {
    await pumpDetailScreen(tester, rol: RolUsuario.admin, estado: EstadoCelda.libre);

    expect(find.widgetWithText(ElevatedButton, 'Poner en mantenimiento'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Volver a libre'), findsNothing);
  });

  testWidgets('ADMIN + MANTENIMIENTO: muestra el botón de volver a libre', (tester) async {
    await pumpDetailScreen(tester, rol: RolUsuario.admin, estado: EstadoCelda.mantenimiento);

    expect(find.widgetWithText(ElevatedButton, 'Volver a libre'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Poner en mantenimiento'), findsNothing);
  });

  testWidgets('ADMIN + OCUPADA: no ofrece ninguna acción', (tester) async {
    await pumpDetailScreen(tester, rol: RolUsuario.admin, estado: EstadoCelda.ocupada);

    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('OPERADOR + LIBRE: no ve ningún botón', (tester) async {
    await pumpDetailScreen(tester, rol: RolUsuario.operador, estado: EstadoCelda.libre);

    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.text('A-01'), findsOneWidget);
  });

  testWidgets('OPERADOR + MANTENIMIENTO: no ve ningún botón', (tester) async {
    await pumpDetailScreen(tester, rol: RolUsuario.operador, estado: EstadoCelda.mantenimiento);

    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('OPERADOR + OCUPADA: muestra el botón de registrar salida', (tester) async {
    await pumpDetailScreen(tester, rol: RolUsuario.operador, estado: EstadoCelda.ocupada);

    expect(find.widgetWithText(ElevatedButton, 'Registrar salida'), findsOneWidget);
  });

  testWidgets('ADMIN + OCUPADA: no ve el botón de registrar salida', (tester) async {
    await pumpDetailScreen(tester, rol: RolUsuario.admin, estado: EstadoCelda.ocupada);

    expect(find.widgetWithText(ElevatedButton, 'Registrar salida'), findsNothing);
  });

  testWidgets('OPERADOR + OCUPADA: tocar el botón busca el ticket abierto y navega a salida', (tester) async {
    when(() => ticketRepository.listar(celdaId: 'c1', estado: EstadoTicket.abierto, perPage: 1)).thenAnswer(
      (_) async => TicketPageResult(
        data: [
          Ticket(
            id: 't1',
            codigo: 'T-260101-ABC123',
            vehiculoId: 'veh1',
            celdaId: 'c1',
            horaEntrada: DateTime.utc(2026, 1, 1, 13),
            tarifaId: 'tar1',
            estado: EstadoTicket.abierto,
            operadorEntradaId: 'op1',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        page: 1,
        perPage: 1,
        total: 1,
      ),
    );

    await pumpDetailScreenConRouter(tester, estado: EstadoCelda.ocupada);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    await tester.pumpAndSettle();

    expect(find.text('SALIDA_t1'), findsOneWidget);
  });

  testWidgets('OPERADOR + OCUPADA: sin ticket abierto encontrado, avisa sin navegar', (tester) async {
    when(() => ticketRepository.listar(celdaId: 'c1', estado: EstadoTicket.abierto, perPage: 1)).thenAnswer(
      (_) async => const TicketPageResult(data: [], page: 1, perPage: 1, total: 0),
    );

    await pumpDetailScreenConRouter(tester, estado: EstadoCelda.ocupada);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar salida'));
    // Un pump (no pumpAndSettle): el SnackBar se auto-oculta tras su
    // duración por defecto, y pumpAndSettle esperaría a que termine ese
    // ciclo completo antes de devolver el control.
    await tester.pump();
    await tester.pump();

    expect(find.text('No se encontró un ticket abierto para esta celda.'), findsOneWidget);
    expect(find.byType(CeldaDetailScreen), findsOneWidget);
  });

  testWidgets('ADMIN: tocar la acción llama al repositorio y refleja el nuevo estado', (tester) async {
    when(() => celdaRepository.marcarMantenimiento('c1')).thenAnswer(
      (_) async => celda(EstadoCelda.mantenimiento),
    );

    await pumpDetailScreen(tester, rol: RolUsuario.admin, estado: EstadoCelda.libre);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Poner en mantenimiento'));
    await tester.pumpAndSettle();

    verify(() => celdaRepository.marcarMantenimiento('c1')).called(1);
    expect(find.widgetWithText(ElevatedButton, 'Volver a libre'), findsOneWidget);
  });
}
