import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
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
import 'package:parqueadero_app/features/turnos/domain/turno.dart';
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

  Turno turno() => Turno(
    id: 'tur1',
    operadorId: 'op1',
    apertura: DateTime.utc(2026, 1, 1, 6),
    baseInicial: 50000,
    estado: EstadoTurno.abierto,
    createdAt: DateTime.utc(2026, 1, 1, 6),
    updatedAt: DateTime.utc(2026, 1, 1, 6),
  );

  // El operador siempre llega al dashboard sin turno abierto en estos tests
  // (mismo fixture de siempre), lo que ahora dispara el diálogo "¿Iniciar
  // turno?". Se simula el estado real: antes de responder, listar() sigue
  // devolviendo vacío; en cuanto abrir() "tiene éxito", empieza a devolver el
  // turno — igual que haría el backend real — para que el refrescar() que
  // sigue a un "Iniciar" no vuelva a disparar el mismo diálogo.
  bool turnoAbiertoSimulado = false;

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    authRepository = MockAuthRepository();
    turnoRepository = MockTurnoRepository();
    celdaRepository = MockCeldaRepository();
    ticketRepository = MockTicketRepository();
    turnoAbiertoSimulado = false;
    when(() => authRepository.restoreSession()).thenAnswer((_) async => operador);
    when(() => authRepository.logout()).thenAnswer((_) async {});
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => turnoAbiertoSimulado
          ? TurnoPageResult(data: [turno()], page: 1, perPage: 1, total: 1)
          : const TurnoPageResult(data: [], page: 1, perPage: 1, total: 0),
    );
    when(() => turnoRepository.abrir()).thenAnswer((_) async {
      turnoAbiertoSimulado = true;
      return turno();
    });
    when(
      () => ticketRepository.listar(estado: any(named: 'estado'), perPage: any(named: 'perPage')),
    ).thenAnswer((_) async => const TicketPageResult(data: [], page: 1, perPage: 100, total: 0));
  });

  String? rutaVisitada;

  /// Por defecto responde "Iniciar" al diálogo apenas aparece, para que el
  /// resto de los tests (navegación, tokens de color, etc.) no tengan que
  /// lidiar con él — mismo espíritu que cualquier operador real al entrar.
  /// Los tests que sí verifican el diálogo pasan `responderIniciar: false`.
  Future<void> pumpDashboard(WidgetTester tester, {bool responderIniciar = true}) async {
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
          path: '/tickets/entrada',
          builder: (context, state) {
            rutaVisitada = '/tickets/entrada';
            return const Scaffold(body: Text('ENTRADA'));
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

    if (responderIniciar && find.text('¿Iniciar turno?').evaluate().isNotEmpty) {
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar'));
      await tester.pumpAndSettle();
    }
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

  testWidgets('Registrar entrada lleva a /tickets/entrada sin celda preseleccionada', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
    await pumpDashboard(tester);

    await tester.tap(find.text('Registrar entrada'));
    await tester.pumpAndSettle();
    expect(rutaVisitada, '/tickets/entrada');
  });

  testWidgets('Ver celdas lleva a /celdas', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
    await pumpDashboard(tester);

    await tester.tap(find.text('Ver celdas'));
    await tester.pumpAndSettle();
    expect(rutaVisitada, '/celdas');
  });

  testWidgets('Registrar salida lleva a /celdas (se elige la celda ocupada a mano)', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
    await pumpDashboard(tester);

    await tester.tap(find.text('Registrar salida'));
    await tester.pumpAndSettle();
    expect(rutaVisitada, '/celdas');
  });

  testWidgets('Buscar placa lleva a /tickets/buscar', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
    await pumpDashboard(tester);

    await tester.tap(find.text('Buscar placa'));
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
  // `asfaltoMedio`, y el link de acción secundario no puede colarse con un
  // color fuera de los tokens.
  testWidgets('Registrar salida usa asfaltoMedio, no un blanco fuera de los tokens', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
    await pumpDashboard(tester);

    final material = tester.widget<Material>(
      find.ancestor(of: find.text('Registrar salida'), matching: find.byType(Material)).first,
    );
    expect(material.color, AppColors.asfaltoMedio);
  });

  // "Registrar entrada" es la única acción con relleno sólido claro de toda
  // la app: es la tarea que más se repite por turno. Sobre `verdePastel` el
  // contenido tiene que invertirse a `asfaltoOscuro` — dejarlo en un token
  // claro lo volvería ilegible.
  testWidgets('Registrar entrada usa verdePastel con contenido en asfaltoOscuro', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
    await pumpDashboard(tester);

    final material = tester.widget<Material>(
      find.ancestor(of: find.text('Registrar entrada'), matching: find.byType(Material)).first,
    );
    expect(material.color, AppColors.verdePastel);

    final texto = tester.widget<Text>(find.text('Registrar entrada'));
    expect(texto.style?.color, AppColors.asfaltoOscuro);

    final icono = tester.widget<Icon>(find.byIcon(Icons.add_box_outlined));
    expect(icono.color, AppColors.asfaltoOscuro);
  });

  group('diálogo "¿Iniciar turno?" (primera vez del día sin turno abierto)', () {
    testWidgets('aparece apenas se detecta que no hay turno, antes de dejar hacer cualquier otra cosa', (
      tester,
    ) async {
      when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
      await pumpDashboard(tester, responderIniciar: false);

      expect(find.text('¿Iniciar turno?'), findsOneWidget);

      // El barrier modal (barrierDismissible: false) bloquea la interacción
      // con lo que hay detrás: tocar "Registrar entrada" no navega.
      await tester.tap(find.text('Registrar entrada'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(rutaVisitada, isNull);
    });

    testWidgets('Iniciar: abre el turno con la baseInicial automática y el diálogo desaparece', (tester) async {
      when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
      await pumpDashboard(tester, responderIniciar: false);

      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar'));
      await tester.pumpAndSettle();

      verify(() => turnoRepository.abrir()).called(1);
      verifyNever(() => authRepository.logout());
      expect(find.text('¿Iniciar turno?'), findsNothing);
    });

    testWidgets('No: cierra la sesión sin abrir ningún turno', (tester) async {
      when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
      await pumpDashboard(tester, responderIniciar: false);

      await tester.tap(find.widgetWithText(TextButton, 'No'));
      await tester.pumpAndSettle();

      verify(() => authRepository.logout()).called(1);
      verifyNever(() => turnoRepository.abrir());
    });

    testWidgets('sin baseInicial configurada: muestra el error del backend y no cierra sesión', (tester) async {
      when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
      when(() => turnoRepository.abrir()).thenThrow(
        const ApiException(
          code: 'BASE_INICIAL_NO_CONFIGURADA',
          message: 'Ningún administrador ha configurado la baseInicial para apertura automática',
          statusCode: 422,
        ),
      );
      await pumpDashboard(tester, responderIniciar: false);

      // No pumpAndSettle(): un SnackBar se auto-descarta a los ~4s reales, y
      // pumpAndSettle avanza el reloj falso hasta que todo se asiente —
      // incluida esa salida — dejándolo ya cerrado antes de poder mirarlo.
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(
        find.text('Ningún administrador ha configurado la baseInicial para apertura automática'),
        findsOneWidget,
      );
      verifyNever(() => authRepository.logout());
    });
  });
}
