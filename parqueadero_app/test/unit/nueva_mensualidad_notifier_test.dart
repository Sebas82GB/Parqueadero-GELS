import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/domain/tipo_vehiculo.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/mensualidades/data/mensualidad_repository_impl.dart';
import 'package:parqueadero_app/features/mensualidades/domain/mensualidad.dart';
import 'package:parqueadero_app/features/mensualidades/domain/mensualidad_repository.dart';
import 'package:parqueadero_app/features/mensualidades/presentation/mensualidad_list_notifier.dart';
import 'package:parqueadero_app/features/mensualidades/presentation/nueva_mensualidad_notifier.dart';

class MockMensualidadRepository extends Mock implements MensualidadRepository {}

void main() {
  late MockMensualidadRepository mensualidadRepository;
  late ProviderContainer container;

  Mensualidad mensualidad() => Mensualidad(
    id: 'm1',
    vehiculoId: 'veh1',
    celdaId: null,
    fechaInicio: DateTime.utc(2026, 1, 1),
    fechaFin: DateTime.utc(2026, 2, 1),
    valorMensualidad: 150000,
    estadoPago: EstadoPagoMensualidad.noPagada,
    fechaPago: null,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(TipoVehiculo.carro);
  });

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
    ).thenAnswer((_) async => const MensualidadPageResult(data: [], page: 1, perPage: 20, total: 0));
    container = ProviderContainer(
      overrides: [mensualidadRepositoryProvider.overrideWithValue(mensualidadRepository)],
    );
    addTearDown(container.dispose);
    container.listen(mensualidadListNotifierProvider, (_, _) {});
  });

  test('éxito: retorna la Mensualidad creada y refresca MensualidadListNotifier', () async {
    when(
      () => mensualidadRepository.crear(
        placa: any(named: 'placa'),
        tipoVehiculo: any(named: 'tipoVehiculo'),
        propietarioNombre: any(named: 'propietarioNombre'),
        propietarioTelefono: any(named: 'propietarioTelefono'),
        celdaId: any(named: 'celdaId'),
        fechaInicio: any(named: 'fechaInicio'),
        fechaFin: any(named: 'fechaFin'),
        valorMensualidad: any(named: 'valorMensualidad'),
      ),
    ).thenAnswer((_) async => mensualidad());
    await Future<void>.delayed(Duration.zero);

    final resultado = await container
        .read(nuevaMensualidadNotifierProvider.notifier)
        .crear(
          placa: 'ABC123',
          tipoVehiculo: TipoVehiculo.carro,
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 2, 1),
          valorMensualidad: 150000,
        );

    expect(resultado?.id, 'm1');
    expect(container.read(nuevaMensualidadNotifierProvider).errorMessage, isNull);
    verify(
      () => mensualidadRepository.listar(
        estadoPago: any(named: 'estadoPago'),
        placa: any(named: 'placa'),
        vigencia: any(named: 'vigencia'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).called(greaterThanOrEqualTo(2));
  });

  for (final caso in [
    (code: 'VALIDATION_ERROR', statusCode: 400, mensaje: 'fechaFin debe ser posterior a fechaInicio'),
    (code: 'CELDA_NO_ENCONTRADA', statusCode: 404, mensaje: 'Celda no encontrada'),
    (code: 'MENSUALIDAD_SOLAPADA', statusCode: 409, mensaje: 'Ya existe una mensualidad vigente que se solapa'),
  ]) {
    test('${caso.code}: expone el mensaje del backend y retorna null', () async {
      when(
        () => mensualidadRepository.crear(
          placa: any(named: 'placa'),
          tipoVehiculo: any(named: 'tipoVehiculo'),
          propietarioNombre: any(named: 'propietarioNombre'),
          propietarioTelefono: any(named: 'propietarioTelefono'),
          celdaId: any(named: 'celdaId'),
          fechaInicio: any(named: 'fechaInicio'),
          fechaFin: any(named: 'fechaFin'),
          valorMensualidad: any(named: 'valorMensualidad'),
        ),
      ).thenThrow(ApiException(code: caso.code, message: caso.mensaje, statusCode: caso.statusCode));

      final resultado = await container
          .read(nuevaMensualidadNotifierProvider.notifier)
          .crear(
            placa: 'ABC123',
            tipoVehiculo: TipoVehiculo.carro,
            fechaInicio: DateTime.utc(2026, 1, 1),
            fechaFin: DateTime.utc(2026, 2, 1),
            valorMensualidad: 150000,
          );

      expect(resultado, isNull);
      expect(container.read(nuevaMensualidadNotifierProvider).errorMessage, caso.mensaje);
    });
  }
}
