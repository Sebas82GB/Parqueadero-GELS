import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/widgets/empty_state.dart';
import 'package:parqueadero_app/core/widgets/error_state.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';
import 'package:parqueadero_app/features/turnos/presentation/turnos_historial_screen.dart';
import 'package:parqueadero_app/features/usuarios/data/usuario_repository_impl.dart';
import 'package:parqueadero_app/features/usuarios/domain/usuario_repository.dart';

class MockTurnoRepository extends Mock implements TurnoRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUsuarioRepository extends Mock implements UsuarioRepository {}

void main() {
  late MockTurnoRepository turnoRepository;
  late MockAuthRepository authRepository;
  late MockUsuarioRepository usuarioRepository;

  Usuario usuario({RolUsuario rol = RolUsuario.operador}) => Usuario(
    id: 'op1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: rol,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Turno turno(String id) => Turno(
    id: id,
    operadorId: 'op1',
    apertura: DateTime.utc(2026, 1, 1, 6),
    baseInicial: 50000,
    estado: EstadoTurno.abierto,
    createdAt: DateTime.utc(2026, 1, 1, 6),
    updatedAt: DateTime.utc(2026, 1, 1, 6),
  );

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    turnoRepository = MockTurnoRepository();
    authRepository = MockAuthRepository();
    usuarioRepository = MockUsuarioRepository();
    when(
      () => usuarioRepository.listar(rol: any(named: 'rol'), activo: any(named: 'activo'), page: any(named: 'page'), perPage: any(named: 'perPage')),
    ).thenAnswer((_) async => const UsuarioPageResult(data: [], page: 1, perPage: 100, total: 0));
  });

  Future<void> pumpHistorial(WidgetTester tester, {RolUsuario rol = RolUsuario.operador}) async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario(rol: rol));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          turnoRepositoryProvider.overrideWithValue(turnoRepository),
          authRepositoryProvider.overrideWithValue(authRepository),
          usuarioRepositoryProvider.overrideWithValue(usuarioRepository),
        ],
        child: const MaterialApp(home: TurnosHistorialScreen()),
      ),
    );
  }

  testWidgets('cargando: muestra el spinner', (tester) async {
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) => Future.delayed(const Duration(milliseconds: 50), () => const TurnoPageResult(data: [], page: 1, perPage: 20, total: 0)));

    await pumpHistorial(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('error: muestra ErrorState con botón de reintentar', (tester) async {
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'No hay conexión con el servidor.', statusCode: 0));

    await pumpHistorial(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
  });

  testWidgets('vacío: sin turnos que coincidan', (tester) async {
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 20, total: 0));

    await pumpHistorial(tester);
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('éxito: lista los turnos y permite cargar más', (tester) async {
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => TurnoPageResult(data: [turno('t1')], page: 1, perPage: 20, total: 2));

    await pumpHistorial(tester);
    await tester.pumpAndSettle();

    // Sesión OPERADOR viendo su propio turno: se resuelve con la propia
    // sesión, sin llamar a GET /usuarios (403 para un OPERADOR).
    expect(find.text('Mi turno'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Cargar más'), findsOneWidget);

    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 2,
        perPage: 20,
      ),
    ).thenAnswer((_) async => TurnoPageResult(data: [turno('t2')], page: 2, perPage: 20, total: 2));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Cargar más'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Cargar más'), findsNothing);
  });

  testWidgets('selector de operador: solo visible para ADMIN', (tester) async {
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 20, total: 0));

    await pumpHistorial(tester);
    await tester.pumpAndSettle();
    expect(find.text('Operador'), findsNothing);
  });

  testWidgets('selector de operador: visible para ADMIN, lista nombres y dispara la consulta', (tester) async {
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 20, total: 0));
    when(
      () => usuarioRepository.listar(
        rol: any(named: 'rol'),
        activo: any(named: 'activo'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => UsuarioPageResult(
        data: [
          Usuario(
            id: 'op2',
            nombre: 'Carlos',
            email: 'carlos@test.com',
            rol: RolUsuario.operador,
            activo: true,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        page: 1,
        perPage: 100,
        total: 1,
      ),
    );

    await pumpHistorial(tester, rol: RolUsuario.admin);
    await tester.pumpAndSettle();

    // Igual que en `tickets_historial_screen_test.dart`/`tarifas_screen_test.dart`:
    // con `value == null` y un `DropdownMenuItem(value: null, ...)` en la
    // lista, Flutter muestra ese item (no el `hint`) como texto visible.
    await tester.tap(find.text('Todos los operadores'));
    await tester.pumpAndSettle();
    expect(find.text('Carlos').last, findsOneWidget);
    await tester.tap(find.text('Carlos').last);
    await tester.pumpAndSettle();

    verify(
      () => turnoRepository.listar(
        operadorId: 'op2',
        estado: any(named: 'estado'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: 20,
      ),
    ).called(1);
  });
}
