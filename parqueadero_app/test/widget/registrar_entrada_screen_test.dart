import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/widgets/empty_state.dart';
import 'package:parqueadero_app/core/widgets/error_state.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/tickets/presentation/registrar_entrada_screen.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';

class MockCeldaRepository extends Mock implements CeldaRepository {}

class MockTicketRepository extends Mock implements TicketRepository {}

class MockTurnoRepository extends Mock implements TurnoRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockCeldaRepository celdaRepository;
  late MockTicketRepository ticketRepository;
  late MockTurnoRepository turnoRepository;
  late MockAuthRepository authRepository;

  setUpAll(() {
    registerFallbackValue(TipoVehiculo.carro);
  });

  final operador = Usuario(
    id: 'op1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: RolUsuario.operador,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Celda celdaLibre() => Celda(
    id: 'cel1',
    codigo: 'A-01',
    zona: 'Zona A',
    tipoPermitido: TipoVehiculo.carro,
    estado: EstadoCelda.libre,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Ticket ticketCreado() => Ticket(
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

  setUp(() {
    celdaRepository = MockCeldaRepository();
    ticketRepository = MockTicketRepository();
    turnoRepository = MockTurnoRepository();
    authRepository = MockAuthRepository();
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celdaLibre()]);
    when(() => authRepository.restoreSession()).thenAnswer((_) async => operador);
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 1, total: 0));
  });

  Future<GoRouter> pumpEntradaScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/celdas',
      routes: [
        GoRoute(
          path: '/celdas',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => context.push('/entrada'), child: const Text('IR_A_ENTRADA')),
            ),
          ),
        ),
        GoRoute(path: '/entrada', builder: (context, state) => const RegistrarEntradaScreen(celdaId: 'cel1')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('IR_A_ENTRADA'));
    await tester.pumpAndSettle();
    return router;
  }

  // Sin indirección de router: estos casos no navegan, solo verifican qué
  // se ve mientras `celdaListNotifierProvider` sigue cargando o falló.
  Future<void> pumpEntradaScreenDirecto(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: RegistrarEntradaScreen(celdaId: 'cel1')),
      ),
    );
  }

  testWidgets('celdas cargando: muestra el spinner, no "celda no encontrada"', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer(
      (_) => Future.delayed(const Duration(milliseconds: 50), () => [celdaLibre()]),
    );

    await pumpEntradaScreenDirecto(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.text('No se encontró la celda seleccionada. Vuelve a la cuadrícula e inténtalo de nuevo.'),
      findsNothing,
    );

    await tester.pumpAndSettle();
  });

  testWidgets('celdas con error: muestra ErrorState con el mensaje del backend, no "celda no encontrada"', (
    tester,
  ) async {
    when(
      () => celdaRepository.listarTodas(),
    ).thenThrow(const ApiException(code: 'INTERNAL_ERROR', message: 'Error de red', statusCode: 500));

    await pumpEntradaScreenDirecto(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Error de red'), findsOneWidget);
    expect(
      find.text('No se encontró la celda seleccionada. Vuelve a la cuadrícula e inténtalo de nuevo.'),
      findsNothing,
    );
  });

  testWidgets('celdas con error: tocar Reintentar vuelve a pedir el listado', (tester) async {
    when(
      () => celdaRepository.listarTodas(),
    ).thenThrow(const ApiException(code: 'INTERNAL_ERROR', message: 'Error de red', statusCode: 500));

    await pumpEntradaScreenDirecto(tester);
    await tester.pumpAndSettle();

    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celdaLibre()]);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Celda A-01'), findsOneWidget);
  });

  testWidgets('celda no existe en el listado ya cargado: muestra EmptyState', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => []);

    await pumpEntradaScreenDirecto(tester);
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(
      find.text('No se encontró la celda seleccionada. Vuelve a la cuadrícula e inténtalo de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('muestra la celda preseleccionada con su tipo permitido', (tester) async {
    await pumpEntradaScreen(tester);

    expect(find.text('Celda A-01'), findsOneWidget);
    expect(find.text('Zona Zona A'), findsOneWidget);
  });

  testWidgets('muestra el indicador de turno activo antes del formulario', (tester) async {
    await pumpEntradaScreen(tester);

    expect(find.text('Sin turno abierto'), findsOneWidget);
  });

  testWidgets('éxito: llama al repositorio, muestra el código y vuelve a celdas', (tester) async {
    when(
      () => ticketRepository.registrarEntrada(
        placa: any(named: 'placa'),
        tipoVehiculo: any(named: 'tipoVehiculo'),
        celdaId: any(named: 'celdaId'),
        propietarioNombre: any(named: 'propietarioNombre'),
        propietarioTelefono: any(named: 'propietarioTelefono'),
      ),
    ).thenAnswer((_) async => ticketCreado());

    await pumpEntradaScreen(tester);
    await tester.enterText(find.byType(TextFormField).first, 'abc123');
    // El botón vive en bottomNavigationBar (fuera del scroll), así que ya no
    // hace falta ensureVisible: siempre está en el viewport, con o sin
    // teclado — justo lo que corrige este cambio.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar entrada'));
    await tester.pumpAndSettle();

    // Sin diálogo "Aceptar": vuelve a celdas de inmediato y confirma con un
    // snackbar que no exige toque.
    expect(find.text('IR_A_ENTRADA'), findsOneWidget);
    expect(find.textContaining('Entrada registrada · Ticket T-260101-ABC123'), findsOneWidget);

    verify(
      () => ticketRepository.registrarEntrada(
        placa: 'ABC123',
        tipoVehiculo: TipoVehiculo.carro,
        celdaId: 'cel1',
        propietarioNombre: any(named: 'propietarioNombre'),
        propietarioTelefono: any(named: 'propietarioTelefono'),
      ),
    ).called(1);
  });

  for (final code in ['CELDA_OCUPADA', 'VEHICULO_CON_TICKET_ABIERTO', 'CELDA_TIPO_INCOMPATIBLE', 'TARIFA_NO_VIGENTE']) {
    testWidgets('$code: muestra el mensaje del backend sin navegar', (tester) async {
      when(
        () => ticketRepository.registrarEntrada(
          placa: any(named: 'placa'),
          tipoVehiculo: any(named: 'tipoVehiculo'),
          celdaId: any(named: 'celdaId'),
          propietarioNombre: any(named: 'propietarioNombre'),
          propietarioTelefono: any(named: 'propietarioTelefono'),
        ),
      ).thenThrow(ApiException(code: code, message: 'mensaje $code', statusCode: 409));

      await pumpEntradaScreen(tester);
      await tester.enterText(find.byType(TextFormField).first, 'ABC123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Registrar entrada'));
      await tester.pumpAndSettle();

      expect(find.text('mensaje $code'), findsOneWidget);
      expect(find.byType(RegistrarEntradaScreen), findsOneWidget);
    });
  }
}
