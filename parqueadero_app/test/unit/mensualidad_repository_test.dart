import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/domain/tipo_vehiculo.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/mensualidades/data/mensualidad_repository_impl.dart';
import 'package:parqueadero_app/features/mensualidades/domain/mensualidad.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _jsonResponse(String path, Map<String, dynamic> data, {int statusCode = 200}) {
  return Response(requestOptions: RequestOptions(path: path), data: data, statusCode: statusCode);
}

DioException _dioError(String path, {required int statusCode, required Map<String, dynamic> errorBody}) {
  final requestOptions = RequestOptions(path: path);
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: requestOptions, statusCode: statusCode, data: errorBody),
  );
}

Map<String, dynamic> _mensualidadJson({
  String id = 'm1',
  String vehiculoId = 'veh1',
  String? celdaId,
  String estadoPago = 'NO_PAGADA',
  String? fechaPago,
}) => {
  'id': id,
  'vehiculoId': vehiculoId,
  'celdaId': celdaId,
  'fechaInicio': '2026-01-01T00:00:00.000Z',
  'fechaFin': '2026-02-01T00:00:00.000Z',
  'valorMensualidad': 150000,
  'estadoPago': estadoPago,
  'fechaPago': fechaPago,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
};

void main() {
  late MockDio dio;
  late MensualidadRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = MensualidadRepositoryImpl(dio);
  });

  group('listar', () {
    test('sin filtros: solo envía page y perPage (nunca diasPorVencer)', () async {
      when(() => dio.get('/mensualidades', queryParameters: {'page': 1, 'perPage': 20})).thenAnswer(
        (_) async => _jsonResponse('/mensualidades', {
          'data': [_mensualidadJson()],
          'meta': {'page': 1, 'perPage': 20, 'total': 1},
        }),
      );

      final resultado = await repository.listar();

      expect(resultado.data, hasLength(1));
      expect(resultado.data.first.estadoPago, EstadoPagoMensualidad.noPagada);
      verify(() => dio.get('/mensualidades', queryParameters: {'page': 1, 'perPage': 20})).called(1);
    });

    test('con todos los filtros: los envía todos como query params', () async {
      when(
        () => dio.get(
          '/mensualidades',
          queryParameters: {
            'estadoPago': 'PAGADA',
            'placa': 'ABC123',
            'vigencia': 'POR_VENCER',
            'page': 1,
            'perPage': 20,
          },
        ),
      ).thenAnswer(
        (_) async => _jsonResponse('/mensualidades', {
          'data': <Map<String, dynamic>>[],
          'meta': {'page': 1, 'perPage': 20, 'total': 0},
        }),
      );

      await repository.listar(
        estadoPago: EstadoPagoMensualidad.pagada,
        placa: 'ABC123',
        vigencia: VigenciaMensualidad.porVencer,
      );

      verify(
        () => dio.get(
          '/mensualidades',
          queryParameters: {
            'estadoPago': 'PAGADA',
            'placa': 'ABC123',
            'vigencia': 'POR_VENCER',
            'page': 1,
            'perPage': 20,
          },
        ),
      ).called(1);
    });

    test('error de red: lanza NetworkException', () async {
      when(() => dio.get('/mensualidades', queryParameters: any(named: 'queryParameters'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/mensualidades'), type: DioExceptionType.connectionError),
      );

      await expectLater(() => repository.listar(), throwsA(isA<NetworkException>()));
    });
  });

  group('crear', () {
    test('éxito: devuelve la Mensualidad creada', () async {
      when(() => dio.post('/mensualidades', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse('/mensualidades', _mensualidadJson()),
      );

      final mensualidad = await repository.crear(
        placa: 'ABC123',
        tipoVehiculo: TipoVehiculo.carro,
        fechaInicio: DateTime.utc(2026, 1, 1),
        fechaFin: DateTime.utc(2026, 2, 1),
        valorMensualidad: 150000,
      );

      expect(mensualidad.id, 'm1');
    });

    test('400 fechas inválidas: lanza ApiException con ese code', () async {
      when(() => dio.post('/mensualidades', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/mensualidades',
          statusCode: 400,
          errorBody: {
            'error': {'code': 'VALIDATION_ERROR', 'message': 'fechaFin debe ser posterior a fechaInicio', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.crear(
          placa: 'ABC123',
          tipoVehiculo: TipoVehiculo.carro,
          fechaInicio: DateTime.utc(2026, 2, 1),
          fechaFin: DateTime.utc(2026, 1, 1),
          valorMensualidad: 150000,
        ),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'VALIDATION_ERROR')),
      );
    });

    test('404 CELDA_NO_ENCONTRADA: lanza ApiException con ese code', () async {
      when(() => dio.post('/mensualidades', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/mensualidades',
          statusCode: 404,
          errorBody: {
            'error': {'code': 'CELDA_NO_ENCONTRADA', 'message': 'Celda no encontrada', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.crear(
          placa: 'ABC123',
          tipoVehiculo: TipoVehiculo.carro,
          celdaId: 'no-existe',
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 2, 1),
          valorMensualidad: 150000,
        ),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CELDA_NO_ENCONTRADA')),
      );
    });

    test('409 MENSUALIDAD_SOLAPADA: lanza ApiException con ese code', () async {
      when(() => dio.post('/mensualidades', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/mensualidades',
          statusCode: 409,
          errorBody: {
            'error': {
              'code': 'MENSUALIDAD_SOLAPADA',
              'message': 'Ya existe una mensualidad vigente que se solapa',
              'details': [],
            },
          },
        ),
      );

      await expectLater(
        () => repository.crear(
          placa: 'ABC123',
          tipoVehiculo: TipoVehiculo.carro,
          fechaInicio: DateTime.utc(2026, 1, 1),
          fechaFin: DateTime.utc(2026, 2, 1),
          valorMensualidad: 150000,
        ),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'MENSUALIDAD_SOLAPADA')),
      );
    });
  });

  group('cancelar', () {
    test('éxito: devuelve la mensualidad con estadoPago CANCELADA', () async {
      when(() => dio.post('/mensualidades/m1/cancelar')).thenAnswer(
        (_) async => _jsonResponse('/mensualidades/m1/cancelar', _mensualidadJson(estadoPago: 'CANCELADA')),
      );

      final mensualidad = await repository.cancelar('m1');

      expect(mensualidad.estadoPago, EstadoPagoMensualidad.cancelada);
    });

    test('409 MENSUALIDAD_YA_CANCELADA: lanza ApiException con ese code', () async {
      when(() => dio.post('/mensualidades/m1/cancelar')).thenThrow(
        _dioError(
          '/mensualidades/m1/cancelar',
          statusCode: 409,
          errorBody: {
            'error': {'code': 'MENSUALIDAD_YA_CANCELADA', 'message': 'La mensualidad ya está cancelada', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.cancelar('m1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'MENSUALIDAD_YA_CANCELADA')),
      );
    });
  });
}
