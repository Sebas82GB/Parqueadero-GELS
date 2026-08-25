import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';
import 'package:parqueadero_app/features/turnos/presentation/abrir_turno_screen.dart';

class MockTurnoRepository extends Mock implements TurnoRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockTurnoRepository turnoRepository;
  late MockAuthRepository authRepository;

  final operador = Usuario(
    id: 'op1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: RolUsuario.operador,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    turnoRepository = MockTurnoRepository();
    authRepository = MockAuthRepository();
    when(() => authRepository.restoreSession()).thenAnswer((_) async => operador);
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 1, total: 0));
  });

  Turno turno() => Turno(
    id: 'tur1',
    operadorId: 'op1',
    apertura: DateTime.utc(2026, 1, 1, 6),
    baseInicial: 50000,
    estado: EstadoTurno.abierto,
    createdAt: DateTime.utc(2026, 1, 1, 6),
    updatedAt: DateTime.utc(2026, 1, 1, 6),
  );

  Future<void> pumpAbrirTurnoScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/salida',
      routes: [
        GoRoute(
          path: '/salida',
          builder: (context, state) => Scaffold(
            body: Center(child: TextButton(onPressed: () => context.push('/turnos/abrir'), child: const Text('IR'))),
          ),
        ),
        GoRoute(path: '/turnos/abrir', builder: (context, state) => const AbrirTurnoScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('IR'));
    await tester.pumpAndSettle();
  }

  testWidgets('campo vacío: no llama al repositorio y no abre el diálogo', (tester) async {
    await pumpAbrirTurnoScreen(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Abrir turno'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa la base inicial'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(() => turnoRepository.abrir(any()));
  });

  testWidgets('el diálogo de confirmación muestra la base formateada', (tester) async {
    await pumpAbrirTurnoScreen(tester);
    await tester.enterText(find.byType(TextFormField), '50000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Abrir turno'));
    await tester.pumpAndSettle();

    expect(find.text('¿Abrir turno?'), findsOneWidget);
    expect(find.textContaining('50.000'), findsOneWidget);
    verifyNever(() => turnoRepository.abrir(any()));
  });

  testWidgets('cancelar en el diálogo: no llama al repositorio y deja el formulario intacto', (tester) async {
    await pumpAbrirTurnoScreen(tester);
    await tester.enterText(find.byType(TextFormField), '50000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Abrir turno'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(AbrirTurnoScreen), findsOneWidget);
    expect(find.text('50000'), findsOneWidget);
    verifyNever(() => turnoRepository.abrir(any()));
  });

  testWidgets('éxito: confirma, muestra el diálogo de éxito y recién ahí vuelve (pop)', (tester) async {
    when(() => turnoRepository.abrir(50000)).thenAnswer((_) async => turno());

    await pumpAbrirTurnoScreen(tester);
    await tester.enterText(find.byType(TextFormField), '50000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Abrir turno'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    verify(() => turnoRepository.abrir(50000)).called(1);
    expect(find.text('Turno abierto'), findsOneWidget);
    expect(find.textContaining('50.000'), findsOneWidget);
    // Todavía no volvió: el diálogo de éxito exige un toque explícito.
    expect(find.text('IR'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Aceptar'));
    await tester.pumpAndSettle();

    expect(find.text('IR'), findsOneWidget);
  });

  testWidgets('error 409: muestra el mensaje del backend sin navegar', (tester) async {
    when(() => turnoRepository.abrir(50000)).thenThrow(
      const ApiException(code: 'TURNO_YA_ABIERTO', message: 'Ya tiene un turno abierto', statusCode: 409),
    );

    await pumpAbrirTurnoScreen(tester);
    await tester.enterText(find.byType(TextFormField), '50000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Abrir turno'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Ya tiene un turno abierto'), findsOneWidget);
    expect(find.byType(AbrirTurnoScreen), findsOneWidget);
  });
}
