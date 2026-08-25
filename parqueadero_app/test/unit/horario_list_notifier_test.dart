import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/horarios/data/horario_repository_impl.dart';
import 'package:parqueadero_app/features/horarios/domain/horario.dart';
import 'package:parqueadero_app/features/horarios/domain/horario_repository.dart';
import 'package:parqueadero_app/features/horarios/presentation/horario_list_notifier.dart';

class MockHorarioRepository extends Mock implements HorarioRepository {}

void main() {
  late MockHorarioRepository horarioRepository;
  late ProviderContainer container;

  Horario horario({
    String id = 'hor1',
    String apertura = '08:00',
    String cierre = '21:00',
    DateTime? vigenteDesde,
    DateTime? vigenteHasta,
  }) => Horario(
    id: id,
    apertura: apertura,
    cierre: cierre,
    vigenteDesde: vigenteDesde ?? DateTime.utc(2026, 1, 1),
    vigenteHasta: vigenteHasta,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    horarioRepository = MockHorarioRepository();
    container = ProviderContainer(
      overrides: [horarioRepositoryProvider.overrideWithValue(horarioRepository)],
    );
    addTearDown(container.dispose);
  });

  void mantenerVivo() => container.listen(horarioListNotifierProvider, (_, _) {});

  test('carga inicial exitosa: pasa de isLoading a la lista completa', () async {
    when(
      () => horarioRepository.listarTodas(),
    ).thenAnswer((_) async => [horario(id: 'h1'), horario(id: 'h2')]);

    mantenerVivo();
    expect(container.read(horarioListNotifierProvider).isLoading, isTrue);

    await Future<void>.delayed(Duration.zero);

    final state = container.read(horarioListNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.horarios, hasLength(2));
  });

  test('carga inicial con error: expone el mensaje del backend', () async {
    when(
      () => horarioRepository.listarTodas(),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'Ha ocurrido un error', statusCode: 500));

    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(horarioListNotifierProvider);
    expect(state.errorMessage, 'Ha ocurrido un error');
    expect(state.horarios, isEmpty);
  });

  test('refrescar() con datos previos: un fallo de fondo no borra la lista ni muestra error', () async {
    when(() => horarioRepository.listarTodas()).thenAnswer((_) async => [horario()]);
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(horarioListNotifierProvider).horarios, hasLength(1));

    when(
      () => horarioRepository.listarTodas(),
    ).thenThrow(const ApiException(code: 'UNKNOWN', message: 'falla de fondo', statusCode: 500));
    await container.read(horarioListNotifierProvider.notifier).refrescar();

    final state = container.read(horarioListNotifierProvider);
    expect(state.horarios, hasLength(1));
    expect(state.errorMessage, isNull);
  });

  group('vigente / historico', () {
    setUp(() async {
      when(() => horarioRepository.listarTodas()).thenAnswer(
        (_) async => [
          horario(
            id: 'viejo',
            apertura: '07:00',
            cierre: '20:00',
            vigenteDesde: DateTime.utc(2025, 1, 1),
            vigenteHasta: DateTime.utc(2026, 1, 1),
          ),
          horario(id: 'vigente', apertura: '08:00', cierre: '21:00', vigenteDesde: DateTime.utc(2026, 1, 1)),
        ],
      );
      mantenerVivo();
      await Future<void>.delayed(Duration.zero);
    });

    test('vigente devuelve el único horario sin vigenteHasta (o futuro)', () {
      final state = container.read(horarioListNotifierProvider);
      expect(state.vigente?.id, 'vigente');
    });

    test('historico excluye el vigente, ordenado por vigenteDesde desc', () {
      final state = container.read(horarioListNotifierProvider);
      expect(state.historico.map((h) => h.id), ['viejo']);
    });
  });

  test('vigente es null cuando ningún horario está vigente', () async {
    when(() => horarioRepository.listarTodas()).thenAnswer(
      (_) async => [
        horario(id: 'cerrado', vigenteDesde: DateTime.utc(2025, 1, 1), vigenteHasta: DateTime.utc(2025, 6, 1)),
      ],
    );
    mantenerVivo();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(horarioListNotifierProvider).vigente, isNull);
  });
}
