import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/theme/app_colors.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/presentation/widgets/admin_home_dashboard.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';
import 'package:parqueadero_app/features/celdas/domain/celda_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCeldaRepository extends Mock implements CeldaRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockCeldaRepository celdaRepository;

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
    celdaRepository = MockCeldaRepository();
    // SessionNotifier restaura sesión al construirse (lo dispara el propio
    // `ref.read(sessionNotifierProvider...)` de "Cerrar sesión"), aunque
    // este dashboard no lee el usuario restaurado para nada más.
    when(() => authRepository.restoreSession()).thenAnswer((_) async => null);
    when(() => authRepository.logout()).thenAnswer((_) async {});
  });

  String? rutaVisitada;

  Future<void> pumpDashboard(WidgetTester tester) async {
    rutaVisitada = null;
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const AdminHomeDashboard()),
        for (final ruta in [
          '/celdas',
          '/tickets/buscar',
          '/tickets',
          '/turnos',
          '/tarifas',
          '/mensualidades',
          '/horarios',
          '/usuarios',
        ])
          GoRoute(
            path: ruta,
            builder: (context, state) {
              rutaVisitada = ruta;
              return Scaffold(body: Text('DESTINO $ruta'));
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
  }

  testWidgets('celdas ocupadas: muestra el conteo real del mismo dato que usa la pantalla de Celdas', (
    tester,
  ) async {
    when(
      () => celdaRepository.listarTodas(),
    ).thenAnswer((_) async => [celda(id: 'c1'), celda(id: 'c2', estado: EstadoCelda.ocupada), celda(id: 'c3', estado: EstadoCelda.ocupada)]);

    await pumpDashboard(tester);

    expect(find.text('2'), findsOneWidget);
    expect(find.text(' / 3'), findsOneWidget);
  });

  testWidgets('celdas ocupadas: error de red muestra "Reintentar" en vez de un conteo en 0 engañoso', (
    tester,
  ) async {
    when(
      () => celdaRepository.listarTodas(),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'No hay conexión con el servidor.', statusCode: 0));

    await pumpDashboard(tester);

    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('ingresos de hoy: sin fuente de dato todavía, muestra el placeholder en vez de inventar un número', (
    tester,
  ) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);

    await pumpDashboard(tester);

    expect(find.text('Ingresos de hoy'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  for (final caso in [
    ('Ver celdas', '/celdas'),
    ('Buscar por placa', '/tickets/buscar'),
    ('Historial', '/tickets'),
    ('Turnos', '/turnos'),
    ('Tarifas', '/tarifas'),
    ('Mensualidades', '/mensualidades'),
    ('Horario de operación', '/horarios'),
    ('Usuarios', '/usuarios'),
  ]) {
    testWidgets('${caso.$1} lleva a ${caso.$2}', (tester) async {
      when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
      await pumpDashboard(tester);

      await tester.ensureVisible(find.text(caso.$1));
      await tester.tap(find.text(caso.$1));
      await tester.pumpAndSettle();
      expect(rutaVisitada, caso.$2);
    });
  }

  testWidgets('Cerrar sesión cierra la sesión', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
    await pumpDashboard(tester);

    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    verify(() => authRepository.logout()).called(1);
  });

  // Regresión de tokens (skill diseno-parqueadero): el mockup de referencia
  // usa #fff para las tarjetas, ajeno a AppColors. Acá debe ser
  // `asfaltoMedio`, igual que el resto de las superficies elevadas de la app.
  testWidgets('la tarjeta de Ingresos de hoy usa asfaltoMedio, no un blanco fuera de los tokens', (tester) async {
    when(() => celdaRepository.listarTodas()).thenAnswer((_) async => const []);
    await pumpDashboard(tester);

    final container = tester.widget<Container>(
      find.ancestor(of: find.text('Ingresos de hoy'), matching: find.byType(Container)).first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppColors.asfaltoMedio);
  });
}
