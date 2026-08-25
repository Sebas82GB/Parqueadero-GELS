import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/widgets/acceso_restringido.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/horarios/data/horario_repository_impl.dart';
import 'package:parqueadero_app/features/horarios/domain/horario.dart';
import 'package:parqueadero_app/features/horarios/domain/horario_repository.dart';
import 'package:parqueadero_app/features/horarios/presentation/nuevo_horario_screen.dart';

class MockHorarioRepository extends Mock implements HorarioRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockHorarioRepository horarioRepository;
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

  Horario horarioCreado() => Horario(
    id: 'hor1',
    apertura: '08:00',
    cierre: '21:00',
    vigenteDesde: DateTime.utc(2026, 1, 1),
    vigenteHasta: null,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  /// Stub de [SeleccionarHora]: devuelve una hora fija según el `helpText`
  /// que la pantalla pasa para cada campo, sin abrir el `TimePickerDialog`
  /// real (ver comentario en `nuevo_horario_screen.dart`).
  SeleccionarHora fakeSeleccionarHora({required TimeOfDay apertura, required TimeOfDay cierre}) {
    return (context, inicial, helpText) async =>
        helpText == 'Hora de apertura' ? apertura : cierre;
  }

  setUp(() {
    horarioRepository = MockHorarioRepository();
    authRepository = MockAuthRepository();
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(RolUsuario.admin));
    when(() => horarioRepository.listarTodas()).thenAnswer((_) async => []);
  });

  Future<GoRouter> pumpNuevoHorarioScreen(
    WidgetTester tester, {
    RolUsuario rol = RolUsuario.admin,
    SeleccionarHora seleccionarHora = defaultSeleccionarHoraParaTest,
  }) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(rol));
    final router = GoRouter(
      initialLocation: '/horarios',
      routes: [
        GoRoute(
          path: '/horarios',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => context.push('/horarios/nuevo'), child: const Text('IR')),
            ),
          ),
        ),
        GoRoute(
          path: '/horarios/nuevo',
          builder: (context, state) => NuevoHorarioScreen(seleccionarHora: seleccionarHora),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          horarioRepositoryProvider.overrideWithValue(horarioRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('IR'));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('OPERADOR: ve el mensaje de acceso restringido', (tester) async {
    await pumpNuevoHorarioScreen(tester, rol: RolUsuario.operador);

    expect(find.byType(AccesoRestringido), findsOneWidget);
  });

  testWidgets('la advertencia sobre cerrar el vigente y no afectar tickets abiertos siempre está visible', (
    tester,
  ) async {
    await pumpNuevoHorarioScreen(tester);

    expect(
      find.textContaining('cierra automáticamente el vigente actual'),
      findsOneWidget,
    );
    expect(find.textContaining('conservan el horario con el que entraron'), findsOneWidget);
  });

  testWidgets('éxito: crea el horario, muestra el diálogo y vuelve atrás', (tester) async {
    when(
      () => horarioRepository.crear(apertura: '08:00', cierre: '21:00'),
    ).thenAnswer((_) async => horarioCreado());

    await pumpNuevoHorarioScreen(
      tester,
      seleccionarHora: fakeSeleccionarHora(
        apertura: const TimeOfDay(hour: 8, minute: 0),
        cierre: const TimeOfDay(hour: 21, minute: 0),
      ),
    );

    await tester.tap(find.byKey(const Key('selector-hora-Apertura')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selector-hora-Cierre')));
    await tester.pumpAndSettle();

    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('21:00'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear horario'));
    await tester.pumpAndSettle();

    expect(find.text('Horario creado'), findsOneWidget);

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    verify(() => horarioRepository.crear(apertura: '08:00', cierre: '21:00')).called(1);
    expect(find.text('IR'), findsOneWidget);
  });

  testWidgets('cierre no posterior a apertura: no llama al repositorio y muestra el error local', (tester) async {
    await pumpNuevoHorarioScreen(
      tester,
      seleccionarHora: fakeSeleccionarHora(
        apertura: const TimeOfDay(hour: 21, minute: 0),
        cierre: const TimeOfDay(hour: 8, minute: 0),
      ),
    );

    await tester.tap(find.byKey(const Key('selector-hora-Apertura')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selector-hora-Cierre')));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear horario'));
    await tester.pumpAndSettle();

    expect(find.text('La hora de cierre debe ser posterior a la de apertura.'), findsOneWidget);
    verifyNever(() => horarioRepository.crear(apertura: any(named: 'apertura'), cierre: any(named: 'cierre')));
  });

  testWidgets('sin seleccionar horas: muestra un aviso y no llama al repositorio', (tester) async {
    await pumpNuevoHorarioScreen(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear horario'));
    await tester.pump();

    expect(find.text('Selecciona la hora de apertura y de cierre.'), findsOneWidget);
    verifyNever(() => horarioRepository.crear(apertura: any(named: 'apertura'), cierre: any(named: 'cierre')));
  });

  testWidgets('400 validación: muestra el mensaje del backend sin navegar', (tester) async {
    when(() => horarioRepository.crear(apertura: '08:00', cierre: '21:00')).thenThrow(
      const ApiException(code: 'VALIDATION_ERROR', message: 'cierre debe ser posterior a apertura', statusCode: 400),
    );

    await pumpNuevoHorarioScreen(
      tester,
      seleccionarHora: fakeSeleccionarHora(
        apertura: const TimeOfDay(hour: 8, minute: 0),
        cierre: const TimeOfDay(hour: 21, minute: 0),
      ),
    );

    await tester.tap(find.byKey(const Key('selector-hora-Apertura')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selector-hora-Cierre')));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear horario'));
    await tester.pumpAndSettle();

    expect(find.text('cierre debe ser posterior a apertura'), findsOneWidget);
    expect(find.byType(NuevoHorarioScreen), findsOneWidget);
  });
}

Future<TimeOfDay?> defaultSeleccionarHoraParaTest(BuildContext context, TimeOfDay? inicial, String helpText) async =>
    inicial;
