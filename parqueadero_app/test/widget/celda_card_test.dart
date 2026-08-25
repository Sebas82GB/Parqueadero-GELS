import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';
import 'package:parqueadero_app/core/theme/app_colors.dart';
import 'package:parqueadero_app/features/celdas/presentation/widgets/celda_card.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCeldaRepository extends Mock implements CeldaRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockCeldaRepository celdaRepository;

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

  setUp(() {
    authRepository = MockAuthRepository();
    celdaRepository = MockCeldaRepository();
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    required RolUsuario rol,
    required EstadoCelda estado,
  }) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(rol));
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celda(estado)]);
    final router = GoRouter(
      initialLocation: '/celdas',
      routes: [
        GoRoute(path: '/celdas', builder: (context, state) => const Scaffold(body: CeldaCard(celdaId: 'c1'))),
        GoRoute(path: '/celdas/:id', builder: (context, state) => const Scaffold(body: Text('DETALLE'))),
        GoRoute(path: '/tickets/entrada', builder: (context, state) => const Scaffold(body: Text('ENTRADA'))),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('OPERADOR + LIBRE: salta directo a registrar entrada con la celda preseleccionada', (tester) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(RolUsuario.operador));
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celda(EstadoCelda.libre)]);
    String? rutaVisitada;
    final router = GoRouter(
      initialLocation: '/celdas',
      routes: [
        GoRoute(path: '/celdas', builder: (context, state) => const Scaffold(body: CeldaCard(celdaId: 'c1'))),
        GoRoute(
          path: '/celdas/:id',
          builder: (context, state) {
            rutaVisitada = '/celdas/${state.pathParameters['id']}';
            return const Scaffold(body: Text('DETALLE'));
          },
        ),
        GoRoute(
          path: '/tickets/entrada',
          builder: (context, state) {
            rutaVisitada = '/tickets/entrada?celdaId=${state.uri.queryParameters['celdaId']}';
            return const Scaffold(body: Text('ENTRADA'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          celdaRepositoryProvider.overrideWithValue(celdaRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CeldaCard));
    await tester.pumpAndSettle();

    expect(rutaVisitada, '/tickets/entrada?celdaId=c1');
  });

  testWidgets('OPERADOR + OCUPADA: sigue yendo al detalle de la celda', (tester) async {
    await pumpCard(tester, rol: RolUsuario.operador, estado: EstadoCelda.ocupada);
    await tester.tap(find.byType(CeldaCard));
    await tester.pumpAndSettle();

    expect(find.text('DETALLE'), findsOneWidget);
  });

  testWidgets('ADMIN + LIBRE: nunca salta el detalle, aunque la celda esté libre', (tester) async {
    await pumpCard(tester, rol: RolUsuario.admin, estado: EstadoCelda.libre);
    await tester.tap(find.byType(CeldaCard));
    await tester.pumpAndSettle();

    expect(find.text('DETALLE'), findsOneWidget);
  });

  testWidgets('OCUPADA: muestra el tiempo transcurrido', (tester) async {
    await pumpCard(tester, rol: RolUsuario.admin, estado: EstadoCelda.ocupada);

    expect(find.textContaining('min'), findsOneWidget);
  });

  testWidgets('LIBRE: no muestra tiempo transcurrido', (tester) async {
    await pumpCard(tester, rol: RolUsuario.admin, estado: EstadoCelda.libre);

    expect(find.textContaining('min'), findsNothing);
  });

  testWidgets('long press: abre las acciones rápidas sin cambiar de pantalla', (tester) async {
    await pumpCard(tester, rol: RolUsuario.admin, estado: EstadoCelda.libre);
    await tester.longPress(find.byType(CeldaCard));
    await tester.pumpAndSettle();

    expect(find.text('Poner en mantenimiento'), findsOneWidget);
    expect(find.text('DETALLE'), findsNothing);
  });

  testWidgets('OCUPADA: el código va en demarcación sobre el relleno asfalto (bahía pintada, no matiz de estado)', (
    tester,
  ) async {
    await pumpCard(tester, rol: RolUsuario.admin, estado: EstadoCelda.ocupada);

    final texto = tester.widget<Text>(find.text('A-01'));

    expect(texto.style?.color, AppColors.demarcacion);
  });

  testWidgets('OPERADOR + OCUPADA: el ícono de acciones rápidas es visible (hay "Registrar salida")', (
    tester,
  ) async {
    await pumpCard(tester, rol: RolUsuario.operador, estado: EstadoCelda.ocupada);

    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });

  testWidgets('ADMIN + LIBRE: el ícono de acciones rápidas es visible (hay "Poner en mantenimiento")', (
    tester,
  ) async {
    await pumpCard(tester, rol: RolUsuario.admin, estado: EstadoCelda.libre);

    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });

  testWidgets('OPERADOR + LIBRE: el ícono NO es visible (el tap normal ya salta a entrada)', (tester) async {
    await pumpCard(tester, rol: RolUsuario.operador, estado: EstadoCelda.libre);

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('ADMIN + OCUPADA: el ícono NO es visible (no hay acción rápida para esa combinación)', (
    tester,
  ) async {
    await pumpCard(tester, rol: RolUsuario.admin, estado: EstadoCelda.ocupada);

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('tocar el ícono abre las mismas acciones rápidas que el long-press', (tester) async {
    await pumpCard(tester, rol: RolUsuario.admin, estado: EstadoCelda.libre);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Poner en mantenimiento'), findsOneWidget);
    expect(find.text('DETALLE'), findsNothing);
  });

  testWidgets(
    'navegar mientras el Hero de la tarjeta está a mitad de cruce (poll de 30s) no lanza "multiple heroes"',
    (tester) async {
      // Reproduce lo que pasó en una corrida real: el poll de 30s (o
      // reemplazarCelda tras registrar entrada/salida) cambia el estado de
      // una celda mientras el operador navega. El AnimatedSwitcher que
      // envuelve el Hero (key: ValueKey(celda.estado)) mantiene montados el
      // Hero saliente Y el entrante durante el cruce — ambos con el MISMO
      // tag (basado solo en celda.id) en el MISMO subárbol. Eso por sí solo
      // no lanza nada (Flutter solo escanea tags duplicados cuando corre una
      // transición de Navigator) — pero si esa transición ocurre justo
      // mientras el cruce está a mitad de camino, `_allHeroesFor` encuentra
      // las dos y lanza "multiple heroes share the same tag within a
      // subtree", tal como se vio en la corrida real.
      var celdaActual = celda(EstadoCelda.libre);
      when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(RolUsuario.admin));
      when(() => celdaRepository.listarTodas()).thenAnswer((_) async => [celdaActual]);
      final router = GoRouter(
        initialLocation: '/celdas',
        routes: [
          GoRoute(path: '/celdas', builder: (context, state) => const Scaffold(body: CeldaCard(celdaId: 'c1'))),
          GoRoute(path: '/celdas/:id', builder: (context, state) => const Scaffold(body: Text('DETALLE'))),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepository),
            celdaRepositoryProvider.overrideWithValue(celdaRepository),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      celdaActual = celda(EstadoCelda.ocupada);
      await tester.pump(const Duration(seconds: 31)); // dispara el poll de CeldaListNotifier
      await tester.pump(); // aplica el nuevo estado: arranca el cruce del AnimatedSwitcher
      await tester.pump(const Duration(milliseconds: 50)); // a mitad del cruce: dos Hero con el mismo tag

      router.push('/celdas/c1'); // transición de Navigator justo en ese instante
      await tester.pump();

      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
