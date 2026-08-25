import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/auth/presentation/session_notifier.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';
import 'package:parqueadero_app/features/turnos/presentation/turno_activo_notifier.dart';

class MockTurnoRepository extends Mock implements TurnoRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockTurnoRepository turnoRepository;
  late MockAuthRepository authRepository;
  late ProviderContainer container;

  final operador = Usuario(
    id: 'op1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: RolUsuario.operador,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Turno turnoAbierto() => Turno(
    id: 'tur1',
    operadorId: 'op1',
    apertura: DateTime.utc(2026, 1, 1, 6),
    baseInicial: 50000,
    estado: EstadoTurno.abierto,
    createdAt: DateTime.utc(2026, 1, 1, 6),
    updatedAt: DateTime.utc(2026, 1, 1, 6),
  );

  Future<void> construirConSesion() async {
    container = ProviderContainer(
      overrides: [
        turnoRepositoryProvider.overrideWithValue(turnoRepository),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
    );
    addTearDown(container.dispose);
    // Mismo precondición que en la app real (el router ya garantiza sesión
    // resuelta antes de mostrar cualquier pantalla con el indicador).
    container.read(sessionNotifierProvider);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    turnoRepository = MockTurnoRepository();
    authRepository = MockAuthRepository();
  });

  test('turno encontrado: lo expone en el estado', () async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => operador);
    when(
      () => turnoRepository.listar(operadorId: 'op1', estado: EstadoTurno.abierto, perPage: 1),
    ).thenAnswer((_) async => TurnoPageResult(data: [turnoAbierto()], page: 1, perPage: 1, total: 1));

    await construirConSesion();
    container.listen(turnoActivoNotifierProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    final state = container.read(turnoActivoNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.turno?.id, 'tur1');
  });

  test('lista vacía: turno queda en null, sin error', () async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => operador);
    when(
      () => turnoRepository.listar(operadorId: 'op1', estado: EstadoTurno.abierto, perPage: 1),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 1, total: 0));

    await construirConSesion();
    container.listen(turnoActivoNotifierProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    final state = container.read(turnoActivoNotifierProvider);
    expect(state.turno, isNull);
    expect(state.errorMessage, isNull);
    expect(state.isLoading, isFalse);
  });

  test('error de red: expone el mensaje del backend', () async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => operador);
    when(
      () => turnoRepository.listar(operadorId: 'op1', estado: EstadoTurno.abierto, perPage: 1),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'No hay conexión con el servidor.', statusCode: 0));

    await construirConSesion();
    container.listen(turnoActivoNotifierProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    final state = container.read(turnoActivoNotifierProvider);
    expect(state.errorMessage, 'No hay conexión con el servidor.');
    expect(state.turno, isNull);
  });

  test('sin usuario en sesión: no llama al repositorio', () async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => null);

    await construirConSesion();
    container.listen(turnoActivoNotifierProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    verifyNever(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        perPage: any(named: 'perPage'),
      ),
    );
  });
}
