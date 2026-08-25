import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/core/network/session_events.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/auth/presentation/session_notifier.dart';
import 'package:parqueadero_app/features/auth/presentation/session_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late SessionEvents sessionEvents;
  late ProviderContainer container;

  final usuario = Usuario(
    id: 'u1',
    nombre: 'Ana',
    email: 'ana@test.com',
    rol: RolUsuario.operador,
    activo: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    authRepository = MockAuthRepository();
    sessionEvents = SessionEvents();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        sessionEventsProvider.overrideWithValue(sessionEvents),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(sessionEvents.dispose);
  });

  test('arranca en checking y pasa a unauthenticated si no hay sesión guardada', () async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => null);

    expect(container.read(sessionNotifierProvider).status, SessionStatus.checking);

    await Future<void>.delayed(Duration.zero);

    expect(container.read(sessionNotifierProvider).status, SessionStatus.unauthenticated);
  });

  test('restaura la sesión guardada: pasa a authenticated con el Usuario', () async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario);

    container.read(sessionNotifierProvider);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(sessionNotifierProvider);
    expect(state.status, SessionStatus.authenticated);
    expect(state.usuario, usuario);
  });

  test('login exitoso: pasa a authenticated', () async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => null);
    when(
      () => authRepository.login(email: any(named: 'email'), password: any(named: 'password')),
    ).thenAnswer((_) async => usuario);

    container.read(sessionNotifierProvider);
    await Future<void>.delayed(Duration.zero);

    await container.read(sessionNotifierProvider.notifier).login(email: 'ana@test.com', password: '12345678');

    expect(container.read(sessionNotifierProvider).status, SessionStatus.authenticated);
  });

  test('login fallido: no cambia el estado y relanza la excepción', () async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => null);
    when(() => authRepository.login(email: any(named: 'email'), password: any(named: 'password'))).thenThrow(
      const ApiException(code: 'CREDENCIALES_INVALIDAS', message: 'Credenciales inválidas', statusCode: 401),
    );

    container.read(sessionNotifierProvider);
    await Future<void>.delayed(Duration.zero);

    await expectLater(
      () => container.read(sessionNotifierProvider.notifier).login(email: 'ana@test.com', password: 'mala'),
      throwsA(isA<ApiException>()),
    );
    expect(container.read(sessionNotifierProvider).status, SessionStatus.unauthenticated);
  });

  test('logout: pasa a unauthenticated', () async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario);
    when(() => authRepository.logout()).thenAnswer((_) async {});

    container.read(sessionNotifierProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(sessionNotifierProvider).status, SessionStatus.authenticated);

    await container.read(sessionNotifierProvider.notifier).logout();

    expect(container.read(sessionNotifierProvider).status, SessionStatus.unauthenticated);
  });

  test('sessionExpired forzado: pasa a unauthenticated sin importar el estado previo', () async {
    when(() => authRepository.restoreSession()).thenAnswer((_) async => usuario);

    container.read(sessionNotifierProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(sessionNotifierProvider).status, SessionStatus.authenticated);

    sessionEvents.emit(SessionEventType.sessionExpired);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(sessionNotifierProvider).status, SessionStatus.unauthenticated);
  });
}
