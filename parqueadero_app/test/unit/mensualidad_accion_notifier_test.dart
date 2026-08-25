import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/mensualidades/data/mensualidad_repository_impl.dart';
import 'package:parqueadero_app/features/mensualidades/domain/mensualidad.dart';
import 'package:parqueadero_app/features/mensualidades/domain/mensualidad_repository.dart';
import 'package:parqueadero_app/features/mensualidades/presentation/mensualidad_accion_notifier.dart';
import 'package:parqueadero_app/features/mensualidades/presentation/mensualidad_list_notifier.dart';

class MockMensualidadRepository extends Mock implements MensualidadRepository {}

void main() {
  late MockMensualidadRepository mensualidadRepository;
  late ProviderContainer container;

  Mensualidad mensualidad({EstadoPagoMensualidad estadoPago = EstadoPagoMensualidad.noPagada}) => Mensualidad(
    id: 'm1',
    vehiculoId: 'veh1',
    celdaId: null,
    fechaInicio: DateTime.utc(2026, 1, 1),
    fechaFin: DateTime.utc(2026, 2, 1),
    valorMensualidad: 150000,
    estadoPago: estadoPago,
    fechaPago: null,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    mensualidadRepository = MockMensualidadRepository();
    when(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => MensualidadPageResult(data: [mensualidad()], page: 1, perPage: 20, total: 1));
    container = ProviderContainer(
      overrides: [mensualidadRepositoryProvider.overrideWithValue(mensualidadRepository)],
    );
    addTearDown(container.dispose);
    container.listen(mensualidadListNotifierProvider, (_, _) {});
    container.listen(mensualidadAccionNotifierProvider('m1'), (_, _) {});
  });

  test('cancelar exitoso: limpia el error y actualiza MensualidadListNotifier', () async {
    when(
      () => mensualidadRepository.cancelar('m1'),
    ).thenAnswer((_) async => mensualidad(estadoPago: EstadoPagoMensualidad.cancelada));
    await Future<void>.delayed(Duration.zero);

    await container.read(mensualidadAccionNotifierProvider('m1').notifier).cancelar();

    final accionState = container.read(mensualidadAccionNotifierProvider('m1'));
    expect(accionState.isLoading, isFalse);
    expect(accionState.errorMessage, isNull);

    final actualizada = container
        .read(mensualidadListNotifierProvider)
        .mensualidades
        .firstWhere((m) => m.id == 'm1');
    expect(actualizada.estadoPago, EstadoPagoMensualidad.cancelada);
  });

  test('cancelar falla con 409 MENSUALIDAD_YA_CANCELADA: expone el mensaje del backend', () async {
    when(() => mensualidadRepository.cancelar('m1')).thenThrow(
      const ApiException(
        code: 'MENSUALIDAD_YA_CANCELADA',
        message: 'La mensualidad ya está cancelada',
        statusCode: 409,
      ),
    );

    await container.read(mensualidadAccionNotifierProvider('m1').notifier).cancelar();

    final accionState = container.read(mensualidadAccionNotifierProvider('m1'));
    expect(accionState.errorMessage, 'La mensualidad ya está cancelada');
  });
}
