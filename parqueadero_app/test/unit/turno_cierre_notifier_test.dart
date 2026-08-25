import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/auth/data/auth_repository_impl.dart';
import 'package:parqueadero_app/features/auth/domain/auth_repository.dart';
import 'package:parqueadero_app/features/auth/domain/usuario.dart';
import 'package:parqueadero_app/features/auth/presentation/session_notifier.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/arqueo_turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';
import 'package:parqueadero_app/features/turnos/presentation/turno_cierre_notifier.dart';
import 'package:parqueadero_app/features/turnos/presentation/turno_cierre_state.dart';

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

  ArqueoTurno arqueo({int efectivoContado = 65000, int diferencia = 0}) => ArqueoTurno(
    turnoId: 'tur1',
    operadorId: 'op1',
    estado: EstadoTurno.cerrado,
    apertura: DateTime.utc(2026, 1, 1, 6),
    cierre: DateTime.utc(2026, 1, 1, 14),
    baseInicial: 50000,
    totalesPorMetodo: const TotalesPorMetodo(efectivo: 15000, tarjeta: 20000, transferencia: 0),
    totalRecaudado: 35000,
    ticketsCerrados: 4,
    efectivoEsperado: 65000,
    efectivoContado: efectivoContado,
    diferencia: diferencia,
  );

  setUp(() async {
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
    container = ProviderContainer(
      overrides: [
        turnoRepositoryProvider.overrideWithValue(turnoRepository),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
    );
    addTearDown(container.dispose);
    // cerrar() refresca turnoActivoNotifierProvider, que lee la sesión;
    // mismo precondición que en abrir_turno_notifier_test.dart.
    container.read(sessionNotifierProvider);
    await Future<void>.delayed(Duration.zero);
  });

  test('cuadre exacto: pasa a éxito con el arqueo devuelto por el backend', () async {
    when(() => turnoRepository.cerrar('tur1', 65000)).thenAnswer((_) async => arqueo());

    final ok = await container.read(turnoCierreNotifierProvider('tur1').notifier).cerrar(65000);

    expect(ok, isTrue);
    final state = container.read(turnoCierreNotifierProvider('tur1'));
    expect(state.step, TurnoCierreStep.exito);
    expect(state.resultado?.diferencia, 0);
  });

  test('sobrante: el resultado no se recalcula, es el que devuelve el backend', () async {
    when(
      () => turnoRepository.cerrar('tur1', 70000),
    ).thenAnswer((_) async => arqueo(efectivoContado: 70000, diferencia: 5000));

    await container.read(turnoCierreNotifierProvider('tur1').notifier).cerrar(70000);

    expect(container.read(turnoCierreNotifierProvider('tur1')).resultado?.diferencia, 5000);
  });

  test('faltante: el resultado no se recalcula, es el que devuelve el backend', () async {
    when(
      () => turnoRepository.cerrar('tur1', 60000),
    ).thenAnswer((_) async => arqueo(efectivoContado: 60000, diferencia: -5000));

    await container.read(turnoCierreNotifierProvider('tur1').notifier).cerrar(60000);

    expect(container.read(turnoCierreNotifierProvider('tur1')).resultado?.diferencia, -5000);
  });

  test('409: vuelve a formulario con el error, sin resultado', () async {
    when(() => turnoRepository.cerrar('tur1', 65000)).thenThrow(
      const ApiException(code: 'CONFLICT', message: 'El turno ya está cerrado', statusCode: 409),
    );

    final ok = await container.read(turnoCierreNotifierProvider('tur1').notifier).cerrar(65000);

    expect(ok, isFalse);
    final state = container.read(turnoCierreNotifierProvider('tur1'));
    expect(state.step, TurnoCierreStep.formulario);
    expect(state.error?.message, 'El turno ya está cerrado');
    expect(state.resultado, isNull);
  });

  test('403: vuelve a formulario con el error', () async {
    when(() => turnoRepository.cerrar('tur1', 65000)).thenThrow(
      const ApiException(code: 'FORBIDDEN', message: 'No tiene permisos sobre este turno', statusCode: 403),
    );

    final ok = await container.read(turnoCierreNotifierProvider('tur1').notifier).cerrar(65000);

    expect(ok, isFalse);
    expect(container.read(turnoCierreNotifierProvider('tur1')).step, TurnoCierreStep.formulario);
  });
}
