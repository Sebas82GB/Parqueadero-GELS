import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/horarios/data/horario_repository_impl.dart';
import 'package:parqueadero_app/features/horarios/domain/horario.dart';
import 'package:parqueadero_app/features/horarios/domain/horario_repository.dart';
import 'package:parqueadero_app/features/horarios/presentation/horario_accion_notifier.dart';
import 'package:parqueadero_app/features/horarios/presentation/horario_list_notifier.dart';

class MockHorarioRepository extends Mock implements HorarioRepository {}

void main() {
  late MockHorarioRepository horarioRepository;
  late ProviderContainer container;

  Horario horario({String apertura = '08:00', String cierre = '21:00', DateTime? vigenteHasta}) => Horario(
    id: 'hor1',
    apertura: apertura,
    cierre: cierre,
    vigenteDesde: DateTime.utc(2026, 1, 1),
    vigenteHasta: vigenteHasta,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    horarioRepository = MockHorarioRepository();
    when(() => horarioRepository.listarTodas()).thenAnswer((_) async => [horario()]);
    container = ProviderContainer(
      overrides: [horarioRepositoryProvider.overrideWithValue(horarioRepository)],
    );
    addTearDown(container.dispose);
    container.listen(horarioListNotifierProvider, (_, _) {});
    container.listen(horarioAccionNotifierProvider('hor1'), (_, _) {});
  });

  group('cerrar', () {
    test('éxito: limpia el error y refresca HorarioListNotifier', () async {
      when(() => horarioRepository.cerrar('hor1')).thenAnswer(
        (_) async => horario(vigenteHasta: DateTime.utc(2026, 2, 1)),
      );
      await Future<void>.delayed(Duration.zero);

      await container.read(horarioAccionNotifierProvider('hor1').notifier).cerrar();

      final accionState = container.read(horarioAccionNotifierProvider('hor1'));
      expect(accionState.isLoading, isFalse);
      expect(accionState.errorMessage, isNull);
      verify(() => horarioRepository.listarTodas()).called(greaterThanOrEqualTo(2));
    });

    test('falla con 409 HORARIO_YA_CERRADO: expone el mensaje del backend', () async {
      when(() => horarioRepository.cerrar('hor1')).thenThrow(
        const ApiException(code: 'HORARIO_YA_CERRADO', message: 'El horario ya está cerrado', statusCode: 409),
      );

      await container.read(horarioAccionNotifierProvider('hor1').notifier).cerrar();

      final accionState = container.read(horarioAccionNotifierProvider('hor1'));
      expect(accionState.errorMessage, 'El horario ya está cerrado');
    });

    test('falla con 404 HORARIO_NO_ENCONTRADO: expone el mensaje del backend', () async {
      when(() => horarioRepository.cerrar('hor1')).thenThrow(
        const ApiException(code: 'HORARIO_NO_ENCONTRADO', message: 'Horario no encontrado', statusCode: 404),
      );

      await container.read(horarioAccionNotifierProvider('hor1').notifier).cerrar();

      expect(container.read(horarioAccionNotifierProvider('hor1')).errorMessage, 'Horario no encontrado');
    });
  });

  group('actualizar', () {
    test('éxito: limpia el error y refresca HorarioListNotifier', () async {
      when(
        () => horarioRepository.actualizar('hor1', apertura: '07:00', cierre: null),
      ).thenAnswer((_) async => horario(apertura: '07:00'));
      await Future<void>.delayed(Duration.zero);

      final resultado = await container
          .read(horarioAccionNotifierProvider('hor1').notifier)
          .actualizar(apertura: '07:00');

      expect(resultado, isTrue);
      final accionState = container.read(horarioAccionNotifierProvider('hor1'));
      expect(accionState.isLoading, isFalse);
      expect(accionState.errorMessage, isNull);
      verify(() => horarioRepository.listarTodas()).called(greaterThanOrEqualTo(2));
    });

    test('falla con 409 HORARIO_CON_TICKETS_ASOCIADOS: expone el mensaje del backend', () async {
      when(() => horarioRepository.actualizar('hor1', apertura: '07:00', cierre: null)).thenThrow(
        const ApiException(
          code: 'HORARIO_CON_TICKETS_ASOCIADOS',
          message: 'No se puede editar un horario que ya tiene tickets asociados',
          statusCode: 409,
        ),
      );

      final resultado = await container
          .read(horarioAccionNotifierProvider('hor1').notifier)
          .actualizar(apertura: '07:00');

      expect(resultado, isFalse);
      expect(
        container.read(horarioAccionNotifierProvider('hor1')).errorMessage,
        'No se puede editar un horario que ya tiene tickets asociados',
      );
    });

    test('falla con 422 HORARIO_RANGO_INVALIDO: expone el mensaje del backend', () async {
      when(() => horarioRepository.actualizar('hor1', apertura: null, cierre: '05:00')).thenThrow(
        const ApiException(
          code: 'HORARIO_RANGO_INVALIDO',
          message: 'El cierre debe ser posterior a la apertura',
          statusCode: 422,
        ),
      );

      final resultado = await container
          .read(horarioAccionNotifierProvider('hor1').notifier)
          .actualizar(cierre: '05:00');

      expect(resultado, isFalse);
      expect(
        container.read(horarioAccionNotifierProvider('hor1')).errorMessage,
        'El cierre debe ser posterior a la apertura',
      );
    });
  });
}
