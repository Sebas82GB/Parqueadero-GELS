import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/turno.dart';
import 'package:parqueadero_app/features/turnos/domain/turno_repository.dart';
import 'package:parqueadero_app/features/turnos/presentation/turno_list_notifier.dart';

class MockTurnoRepository extends Mock implements TurnoRepository {}

void main() {
  late MockTurnoRepository turnoRepository;
  late ProviderContainer container;

  Turno turno(String id) => Turno(
    id: id,
    operadorId: 'op1',
    apertura: DateTime.utc(2026, 1, 1, 6),
    baseInicial: 50000,
    estado: EstadoTurno.abierto,
    createdAt: DateTime.utc(2026, 1, 1, 6),
    updatedAt: DateTime.utc(2026, 1, 1, 6),
  );

  setUp(() {
    turnoRepository = MockTurnoRepository();
    container = ProviderContainer(
      overrides: [turnoRepositoryProvider.overrideWithValue(turnoRepository)],
    );
    addTearDown(container.dispose);
  });

  void mantenerVivo() => container.listen(turnoListNotifierProvider, (_, _) {});

  test('carga inicial exitosa: pasa de isLoading a la lista', () async {
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => TurnoPageResult(data: [turno('t1'), turno('t2')], page: 1, perPage: 20, total: 2));

    mantenerVivo();
    expect(container.read(turnoListNotifierProvider).isLoading, isTrue);

    await Future<void>.delayed(Duration.zero);

    final state = container.read(turnoListNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.turnos, hasLength(2));
    expect(state.hayMas, isFalse);
  });

  test('cargarMas: pide la página siguiente y concatena', () async {
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
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(turnoListNotifierProvider).hayMas, isTrue);

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

    await container.read(turnoListNotifierProvider.notifier).cargarMas();

    final state = container.read(turnoListNotifierProvider);
    expect(state.turnos.map((t) => t.id), ['t1', 't2']);
    expect(state.hayMas, isFalse);
  });

  test('cambiar filtro de estado reinicia a página 1', () async {
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => TurnoPageResult(data: [turno('t1')], page: 1, perPage: 20, total: 1));
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    container.read(turnoListNotifierProvider.notifier).setEstadoFiltro(EstadoTurno.cerrado);
    await Future<void>.delayed(Duration.zero);

    verify(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: EstadoTurno.cerrado,
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: 20,
      ),
    ).called(1);
    expect(container.read(turnoListNotifierProvider).estadoFiltro, EstadoTurno.cerrado);
  });

  test('filtro por operadorId (solo relevante para ADMIN)', () async {
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: 20,
      ),
    ).thenAnswer((_) async => TurnoPageResult(data: [turno('t1')], page: 1, perPage: 20, total: 1));
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    container.read(turnoListNotifierProvider.notifier).setOperadorIdFiltro('op2');
    await Future<void>.delayed(Duration.zero);

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

  test('error en cargarMas de fondo no borra la lista ya visible', () async {
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
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 2,
        perPage: 20,
      ),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'falla de fondo', statusCode: 500));

    await container.read(turnoListNotifierProvider.notifier).cargarMas();

    final state = container.read(turnoListNotifierProvider);
    expect(state.turnos, hasLength(1));
    expect(state.errorMessage, isNull);
  });

  test('carga inicial con error: expone el mensaje y lista vacía', () async {
    when(
      () => turnoRepository.listar(
        operadorId: any(named: 'operadorId'),
        estado: any(named: 'estado'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
        page: 1,
        perPage: 20,
      ),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'Ha ocurrido un error', statusCode: 500));

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(turnoListNotifierProvider);
    expect(state.errorMessage, 'Ha ocurrido un error');
    expect(state.turnos, isEmpty);
  });
}
