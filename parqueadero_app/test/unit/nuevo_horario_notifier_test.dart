import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/horarios/data/horario_repository_impl.dart';
import 'package:parqueadero_app/features/horarios/domain/horario.dart';
import 'package:parqueadero_app/features/horarios/domain/horario_repository.dart';
import 'package:parqueadero_app/features/horarios/presentation/horario_list_notifier.dart';
import 'package:parqueadero_app/features/horarios/presentation/nuevo_horario_notifier.dart';

class MockHorarioRepository extends Mock implements HorarioRepository {}

void main() {
  late MockHorarioRepository horarioRepository;
  late ProviderContainer container;

  Horario horario() => Horario(
    id: 'hor1',
    apertura: '08:00',
    cierre: '21:00',
    vigenteDesde: DateTime.utc(2026, 1, 1),
    vigenteHasta: null,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    horarioRepository = MockHorarioRepository();
    // horarioListNotifierProvider arranca su propia carga al construirse, y
    // NuevoHorarioNotifier.crear() la refresca de nuevo tras crear.
    when(() => horarioRepository.listarTodas()).thenAnswer((_) async => []);
    container = ProviderContainer(
      overrides: [horarioRepositoryProvider.overrideWithValue(horarioRepository)],
    );
    addTearDown(container.dispose);
    container.listen(horarioListNotifierProvider, (_, _) {});
  });

  test('éxito: retorna el Horario creado y refresca HorarioListNotifier', () async {
    when(
      () => horarioRepository.crear(apertura: any(named: 'apertura'), cierre: any(named: 'cierre')),
    ).thenAnswer((_) async => horario());
    await Future<void>.delayed(Duration.zero);

    final resultado = await container
        .read(nuevoHorarioNotifierProvider.notifier)
        .crear(apertura: '08:00', cierre: '21:00');

    expect(resultado?.id, 'hor1');
    expect(container.read(nuevoHorarioNotifierProvider).errorMessage, isNull);
    verify(() => horarioRepository.listarTodas()).called(greaterThanOrEqualTo(2));
  });

  test('400 validación: expone el mensaje del backend y retorna null', () async {
    when(
      () => horarioRepository.crear(apertura: any(named: 'apertura'), cierre: any(named: 'cierre')),
    ).thenThrow(
      const ApiException(code: 'VALIDATION_ERROR', message: 'cierre debe ser posterior a apertura', statusCode: 400),
    );

    final resultado = await container
        .read(nuevoHorarioNotifierProvider.notifier)
        .crear(apertura: '21:00', cierre: '08:00');

    expect(resultado, isNull);
    expect(container.read(nuevoHorarioNotifierProvider).errorMessage, 'cierre debe ser posterior a apertura');
  });
}
