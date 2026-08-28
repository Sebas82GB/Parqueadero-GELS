import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';
import 'package:parqueadero_app/features/auth/presentation/session_notifier.dart';
import 'package:parqueadero_app/features/turnos/presentation/abrir_turno_notifier.dart';
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

  Turno turno() => Turno(
    id: 'tur1',
    operadorId: 'op1',
    apertura: DateTime.utc(2026, 1, 1, 6),
    baseInicial: 50000,
    estado: EstadoTurno.abierto,
    createdAt: DateTime.utc(2026, 1, 1, 6),
    updatedAt: DateTime.utc(2026, 1, 1, 6),
  );

  setUp(() async {
    turnoRepository = MockTurnoRepository();
    authRepository = MockAuthRepository();
    when(() => authRepository.restoreSession()).thenAnswer((_) async => operador);
    container = ProviderContainer(
      overrides: [
        turnoRepositoryProvider.overrideWithValue(turnoRepository),
        // AbrirTurnoNotifier.abrir() refresca turnoActivoNotifierProvider al
        // tener éxito, y ese notifier lee sessionNotifierProvider — sin esta
        // sobrescritura construiría el AuthRepository real (dioProvider →
        // appConfigProvider, que lanza si no se sobrescribió en main()).
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
    );
    addTearDown(container.dispose);
    // En la app real, cuando se llega a una pantalla que muestra el
    // indicador de turno activo, el router ya garantiza sesión resuelta
    // (redirect gate). Acá se simula ese precondición esperando a que
    // `_restore()` termine, para no correr contra una sesión todavía en
    // `checking` (que dejaría a `usuario` en `null`).
    container.read(sessionNotifierProvider);
    await Future<void>.delayed(Duration.zero);
  });

  test('éxito: retorna true y limpia el error', () async {
    when(() => turnoRepository.abrir(50000)).thenAnswer((_) async => turno());
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 1, total: 0));

    final ok = await container.read(abrirTurnoNotifierProvider.notifier).abrir(50000);

    expect(ok, isTrue);
    expect(container.read(abrirTurnoNotifierProvider).errorMessage, isNull);
  });

  test('éxito: refresca turnoActivoNotifierProvider con el operador de la sesión', () async {
    when(() => turnoRepository.abrir(50000)).thenAnswer((_) async => turno());
    when(
      () => turnoRepository.listar(operadorId: 'op1', estado: EstadoTurno.abierto, perPage: 1),
    ).thenAnswer((_) async => TurnoPageResult(data: [turno()], page: 1, perPage: 1, total: 1));

    await container.read(abrirTurnoNotifierProvider.notifier).abrir(50000);

    expect(container.read(turnoActivoNotifierProvider).turno?.id, 'tur1');
    verify(() => turnoRepository.listar(operadorId: 'op1', estado: EstadoTurno.abierto, perPage: 1)).called(1);
  });

  test('sin baseInicial: la pasa tal cual al repositorio (usa la automática del backend)', () async {
    when(() => turnoRepository.abrir()).thenAnswer((_) async => turno());
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const TurnoPageResult(data: [], page: 1, perPage: 1, total: 0));

    final ok = await container.read(abrirTurnoNotifierProvider.notifier).abrir();

    expect(ok, isTrue);
    verify(() => turnoRepository.abrir()).called(1);
  });

  test('error: retorna false y expone el mensaje del backend', () async {
    when(() => turnoRepository.abrir(50000)).thenThrow(
      const ApiException(code: 'TURNO_YA_ABIERTO', message: 'Ya tiene un turno abierto', statusCode: 409),
    );

    final ok = await container.read(abrirTurnoNotifierProvider.notifier).abrir(50000);

    expect(ok, isFalse);
    expect(container.read(abrirTurnoNotifierProvider).errorMessage, 'Ya tiene un turno abierto');
  });
}
