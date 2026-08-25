import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/arqueo_turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';
import 'package:parqueadero_app/features/turnos/presentation/turno_detail_notifier.dart';

class MockTurnoRepository extends Mock implements TurnoRepository {}

void main() {
  late MockTurnoRepository turnoRepository;
  late ProviderContainer container;

  ArqueoTurno arqueo({EstadoTurno estado = EstadoTurno.cerrado, int? efectivoContado, int? diferencia}) => ArqueoTurno(
    turnoId: 'tur1',
    operadorId: 'op1',
    estado: estado,
    apertura: DateTime.utc(2026, 1, 1, 6),
    cierre: estado == EstadoTurno.cerrado ? DateTime.utc(2026, 1, 1, 14) : null,
    baseInicial: 50000,
    totalesPorMetodo: const TotalesPorMetodo(efectivo: 15000, tarjeta: 20000, transferencia: 0),
    totalRecaudado: 35000,
    ticketsCerrados: 4,
    efectivoEsperado: 65000,
    efectivoContado: efectivoContado,
    diferencia: diferencia,
  );

  setUp(() {
    turnoRepository = MockTurnoRepository();
    container = ProviderContainer(
      overrides: [turnoRepositoryProvider.overrideWithValue(turnoRepository)],
    );
    addTearDown(container.dispose);
  });

  void mantenerVivo() => container.listen(turnoDetailNotifierProvider('tur1'), (_, _) {});

  test('éxito abierto: efectivoContado y diferencia llegan en null', () async {
    when(
      () => turnoRepository.obtenerArqueo('tur1'),
    ).thenAnswer((_) async => arqueo(estado: EstadoTurno.abierto));

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(turnoDetailNotifierProvider('tur1'));
    expect(state.isLoading, isFalse);
    expect(state.arqueo?.estado, EstadoTurno.abierto);
    expect(state.arqueo?.efectivoContado, isNull);
    expect(state.arqueo?.diferencia, isNull);
  });

  test('éxito cerrado: trae los valores finales', () async {
    when(() => turnoRepository.obtenerArqueo('tur1')).thenAnswer(
      (_) async => arqueo(efectivoContado: 65000, diferencia: 0),
    );

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(turnoDetailNotifierProvider('tur1'));
    expect(state.arqueo?.estado, EstadoTurno.cerrado);
    expect(state.arqueo?.diferencia, 0);
  });

  test('404: expone el mensaje del backend', () async {
    when(() => turnoRepository.obtenerArqueo('tur1')).thenThrow(
      const ApiException(code: 'NOT_FOUND', message: 'Turno no encontrado', statusCode: 404),
    );

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(turnoDetailNotifierProvider('tur1'));
    expect(state.errorMessage, 'Turno no encontrado');
    expect(state.arqueo, isNull);
  });
}
