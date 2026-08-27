import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/theme/app_colors.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/auth/presentation/widgets/operador_home_dashboard.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTurnoRepository extends Mock implements TurnoRepository {}

class MockCeldaRepository extends Mock implements CeldaRepository {}

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockTurnoRepository turnoRepository;
  late MockCeldaRepository celdaRepository;
  late MockTicketRepository ticketRepository;

  final operador = Usuario(
    id: 'op1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: RolUsuario.operador,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Celda celda({required String id, EstadoCelda estado = EstadoCelda.libre}) => Celda(
    id: id,
    codigo: id,
    zona: 'A',
    tipoPermitido: TipoVehiculo.carro,
    estado: estado,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    authRepository = MockAuthRepository();
    turnoRepository = MockTurnoRepository();
    celdaRepository = MockCeldaRepository();
    ticketRepository = MockTicketRepository();
    when(() => authRepository.restoreSession()).thenAnswer((_) async => operador);
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 1, total: 0));
    when(
      () => ticketRepository.listar(estado: any(named: 'estado'), perPage: any(named: 'perPage')),
    ).thenAnswer((_) async => const TicketPageResult(data: [], page: 1, perPage: 100, total: 0));
  });

  String? rutaVisitada;

  Future<void> pumpDashboard(WidgetTester tester) async {
    rutaVisitada = null;
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const OperadorHomeDashboard()),
        GoRoute(
          path: '/celdas',
          builder: (context, state) {
            rutaVisitada = '/celdas';
            return const Scaffold(body: Text('CELDAS'));
          },
        ),
        GoRoute(
          path: '/tickets/buscar',
          builder: (context, state) {
            rutaVisitada = '/tickets/buscar';
            return const Scaffold(body: Text('BUSCAR'));
          },
        ),
        GoRoute(
          path: '/turnos',
          builder: (context, state) {
            rutaVisitada = '/turnos';
            return const Scaffold(body: Text('TURNOS'));
          },
        ),
        GoRoute(
          path: '/tickets',
          builder: (context, state) {
            rutaVisitada = '/tickets';
            return const Scaffold(body: Text('HISTORIAL'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('celdas libres: muestra el conteo real una vez carga', (tester) async {
    when(
      () => celdaRepository.listarTodas(),
    ).thenAnswer((_) async => [celda(id: 'c1'), celda(id: 'c2'), celda(id: 'c3', estado: EstadoCelda.ocupada)]);

    await pumpDashboard(tester);

    expect(find.text('2'), findsOneWidget);
    expect(find.text(' / 3'), findsOneWidget);
  });

  testWidgets('celdas libres: error de red muestra "Reintentar" en vez de un conteo en 0 engañoso', (tester) async {
    when(
      () => celdaRepository.listarTodas(),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'No hay conexión con el servidor.', statusCode: 0));

    await pumpDashboard(tester);

    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text(' / 0'), findsNothing);
  });

  testWidgets('Registrar entrada y Ver celdas llevan a /celdas', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
    await pumpDashboard(tester);

    await tester.tap(find.text('Registrar entrada'));
    await tester.pumpAndSettle();
    expect(rutaVisitada, '/celdas');
  });

  testWidgets('Registrar salida y Buscar placa llevan a /tickets/buscar', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
    await pumpDashboard(tester);

    await tester.tap(find.text('Registrar salida'));
    await tester.pumpAndSettle();
    expect(rutaVisitada, '/tickets/buscar');
  });

  testWidgets('menú secundario: Turnos, Historial y Cerrar sesión siguen accesibles', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
    await pumpDashboard(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Turnos'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);

    await tester.tap(find.text('Turnos'));
    await tester.pumpAndSettle();
    expect(rutaVisitada, '/turnos');
  });

  // Regresión de tokens (skill diseno-parqueadero): "Registrar salida" en el
  // mockup usa fondo blanco (#fff), ajeno a AppColors — acá debe ser
  // `concreto`, y el link de acción secundario no puede colarse con un color
  // fuera de los 6 tokens.
  testWidgets('Registrar salida usa concreto, no un blanco fuera de los tokens', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
    await pumpDashboard(tester);

    final material = tester.widget<Material>(
      find.ancestor(of: find.text('Registrar salida'), matching: find.byType(Material)).first,
    );
    expect(material.color, AppColors.concreto);
  });
}
