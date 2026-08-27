import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/widgets/animated_count_text.dart';
import 'package:parqueadero_app/core/widgets/empty_state.dart';
import 'package:parqueadero_app/core/widgets/error_state.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/features/celdas/presentation/celdas_screen.dart';
import 'package:parqueadero_app/features/celdas/presentation/widgets/celda_grid_skeleton.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket_repository.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';

class MockCeldaRepository extends Mock implements CeldaRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTurnoRepository extends Mock implements TurnoRepository {}

class MockTicketRepository extends Mock implements TicketRepository {}

void main() {
  late MockCeldaRepository celdaRepository;
  late MockAuthRepository authRepository;
  late MockTicketRepository ticketRepository;

  final adminDePrueba = Usuario(
    id: 'u1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: RolUsuario.admin,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Celda celda({
    required String id,
    required String codigo,
    required String zona,
    EstadoCelda estado = EstadoCelda.libre,
  }) => Celda(
    id: id,
    codigo: codigo,
    zona: zona,
    tipoPermitido: TipoVehiculo.carro,
    estado: estado,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    celdaRepository = MockCeldaRepository();
    authRepository = MockAuthRepository();
    ticketRepository = MockTicketRepository();
    when(() => authRepository.restoreSession()).thenAnswer((_) async => adminDePrueba);
    // El GET adicional de placas por celda (ver CeldaListNotifier.refrescar):
    // ningún test de esta pantalla verifica su contenido, solo que no rompa
    // el refresco de celdas si no hay tickets abiertos.
    when(
      () => ticketRepository.listar(estado: any(named: 'estado'), perPage: any(named: 'perPage')),
    ).thenAnswer((_) async => const TicketPageResult(data: [], page: 1, perPage: 100, total: 0));
  });

  // CeldaCard lee sessionNotifierProvider (para decidir la navegación del
  // tap), así que authRepositoryProvider también se sobrescribe acá — igual
  // que en celda_detail_screen_test.dart — para evitar construir
  // dioProvider/tokenStorageProvider reales.
  Future<void> pumpCeldasScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
        ],
        child: const MaterialApp(home: CeldasScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('cargando: muestra el skeleton de la grilla', (tester) async {
    final completer = Completer<List<Celda>>();
    when(() => celdaRepository.listarTodas()).thenAnswer((_) => completer.future);

    await pumpCeldasScreen(tester);

    expect(find.byType(CeldaGridSkeleton), findsOneWidget);

    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('error: muestra el mensaje del backend con botón de reintentar', (tester) async {
    when(() => celdaRepository.listarTodas()).thenThrow(
      const ApiException(code: 'UNKNOWN', message: 'No hay conexión con el servidor.', statusCode: 0),
    );

    await pumpCeldasScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);

    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => []);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsNothing);
  });

  testWidgets('vacío: sin celdas registradas muestra el mensaje de vacío', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => []);

    await pumpCeldasScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No hay celdas registradas en el parqueadero.'), findsOneWidget);
  });

  testWidgets('éxito: agrupa por zona con el contador de disponibilidad correcto', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer(
      (_) async => [
        celda(id: 'c1', codigo: 'A-01', zona: 'Zona A', estado: EstadoCelda.libre),
        celda(id: 'c2', codigo: 'A-02', zona: 'Zona A', estado: EstadoCelda.ocupada),
        celda(id: 'c3', codigo: 'B-01', zona: 'Zona B', estado: EstadoCelda.libre),
      ],
    );

    await pumpCeldasScreen(tester);
    await tester.pumpAndSettle();

    int contadorDe(String key) => tester
        .widget<AnimatedCountText>(
          find.descendant(of: find.byKey(Key(key)), matching: find.byType(AnimatedCountText)),
        )
        .value;

    expect(contadorDe('resumen-libre'), 2);
    expect(contadorDe('resumen-ocupada'), 1);
    expect(contadorDe('resumen-mantenimiento'), 0);
    expect(find.text('Zona A'), findsOneWidget);
    expect(find.textContaining('/2 libres'), findsOneWidget);
    expect(find.text('Zona B'), findsOneWidget);
    expect(find.textContaining('/1 libres'), findsOneWidget);
    expect(find.text('A-01'), findsOneWidget);
    expect(find.text('B-01'), findsOneWidget);
    // A-02 está OCUPADA: el rediseño de CeldaCard ya no muestra el código
    // ahí (queda el ícono de tipo + tiempo transcurrido; el código se ve en
    // el panel de acción rápida al tocarla).
    expect(find.text('A-02'), findsNothing);
  });

  testWidgets('cargando: el skeleton reproduce la forma de mini-tarjeta', (tester) async {
    final completer = Completer<List<Celda>>();
    when(() => celdaRepository.listarTodas()).thenAnswer((_) => completer.future);

    await pumpCeldasScreen(tester);

    expect(find.byType(CeldaGridSkeleton), findsOneWidget);
    expect(find.byType(Card), findsWidgets);

    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('OPERADOR: muestra el indicador de turno activo sobre la grilla', (tester) async {
    final operador = Usuario(
      id: 'op1',
      nombre: 'Carlos',
      email: 'carlos@test.com',
      rol: RolUsuario.operador,
      activo: true,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    final turnoRepository = MockTurnoRepository();
    when(() => authRepository.restoreSession()).thenAnswer((_) async => operador);
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => []);
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 1, total: 0));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          ticketRepositoryProvider.overrideWithValue(ticketRepository),
        ],
        child: const MaterialApp(home: CeldasScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin turno abierto'), findsOneWidget);
  });
}
