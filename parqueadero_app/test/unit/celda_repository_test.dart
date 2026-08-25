import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/celdas/data/celda_repository_impl.dart';
import 'package:parqueadero_app/features/celdas/domain/celda.dart';

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

Map<String, dynamic> _celdaJson({
  String id = 'c1',
  String codigo = 'A-01',
  String zona = 'Zona A',
  String tipoPermitido = 'CARRO',
  String estado = 'LIBRE',
}) => {
  'id': id,
  'codigo': codigo,
  'zona': zona,
  'tipoPermitido': tipoPermitido,
  'estado': estado,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
};

void main() {
  late MockDio dio;
  late CeldaRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = CeldaRepositoryImpl(dio);
  });

  group('listarTodas', () {
    test('una sola página: hace una llamada y devuelve la lista mapeada', () async {
      when(() => dio.get('/celdas', queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => _jsonResponse('/celdas', {
          'data': [_celdaJson(id: 'c1'), _celdaJson(id: 'c2')],
          'meta': {'page': 1, 'perPage': 100, 'total': 2},
        }),
      );

      final celdas = await repository.listarTodas();

      expect(celdas, hasLength(2));
      expect(celdas.first.id, 'c1');
      expect(celdas.first.tipoPermitido, TipoVehiculo.carro);
      expect(celdas.first.estado, EstadoCelda.libre);
      verify(() => dio.get('/celdas', queryParameters: {'page': 1, 'perPage': 100})).called(1);
    });

    test('varias páginas: pagina hasta agotar el total y combina la lista', () async {
      when(() => dio.get('/celdas', queryParameters: {'page': 1, 'perPage': 100})).thenAnswer(
        (_) async => _jsonResponse('/celdas', {
          'data': List.generate(100, (i) => _celdaJson(id: 'c$i')),
          'meta': {'page': 1, 'perPage': 100, 'total': 150},
        }),
      );
      when(() => dio.get('/celdas', queryParameters: {'page': 2, 'perPage': 100})).thenAnswer(
        (_) async => _jsonResponse('/celdas', {
          'data': List.generate(50, (i) => _celdaJson(id: 'c${100 + i}')),
          'meta': {'page': 2, 'perPage': 100, 'total': 150},
        }),
      );

      final celdas = await repository.listarTodas();

      expect(celdas, hasLength(150));
      verify(() => dio.get('/celdas', queryParameters: {'page': 1, 'perPage': 100})).called(1);
      verify(() => dio.get('/celdas', queryParameters: {'page': 2, 'perPage': 100})).called(1);
    });

    test('total en cero: una sola llamada y lista vacía', () async {
      when(() => dio.get('/celdas', queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => _jsonResponse('/celdas', {
          'data': <Map<String, dynamic>>[],
          'meta': {'page': 1, 'perPage': 100, 'total': 0},
        }),
      );

      final celdas = await repository.listarTodas();

      expect(celdas, isEmpty);
      verify(() => dio.get('/celdas', queryParameters: any(named: 'queryParameters'))).called(1);
    });

    test('error de red: lanza NetworkException', () async {
      when(() => dio.get('/celdas', queryParameters: any(named: 'queryParameters'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/celdas'), type: DioExceptionType.connectionError),
      );

      await expectLater(() => repository.listarTodas(), throwsA(isA<NetworkException>()));
    });
  });

  group('marcarMantenimiento', () {
    test('éxito: devuelve la celda con estado MANTENIMIENTO', () async {
      when(() => dio.patch('/celdas/c1/mantenimiento')).thenAnswer(
        (_) async => _jsonResponse('/celdas/c1/mantenimiento', _celdaJson(estado: 'MANTENIMIENTO')),
      );

      final celda = await repository.marcarMantenimiento('c1');

      expect(celda.estado, EstadoCelda.mantenimiento);
    });

    test('404: lanza ApiException con code CELDA_NO_ENCONTRADA', () async {
      when(() => dio.patch('/celdas/c1/mantenimiento')).thenThrow(
        _dioError(
          '/celdas/c1/mantenimiento',
          statusCode: 404,
          errorBody: {
            'error': {'code': 'CELDA_NO_ENCONTRADA', 'message': 'Celda no encontrada', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.marcarMantenimiento('c1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CELDA_NO_ENCONTRADA')),
      );
    });

    test('409 CELDA_OCUPADA: lanza ApiException con ese code', () async {
      when(() => dio.patch('/celdas/c1/mantenimiento')).thenThrow(
        _dioError(
          '/celdas/c1/mantenimiento',
          statusCode: 409,
          errorBody: {
            'error': {'code': 'CELDA_OCUPADA', 'message': 'La celda A-01 ya está ocupada', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.marcarMantenimiento('c1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CELDA_OCUPADA')),
      );
    });

    test('409 CELDA_ESTADO_INVALIDO: lanza ApiException con ese code', () async {
      when(() => dio.patch('/celdas/c1/mantenimiento')).thenThrow(
        _dioError(
          '/celdas/c1/mantenimiento',
          statusCode: 409,
          errorBody: {
            'error': {
              'code': 'CELDA_ESTADO_INVALIDO',
              'message': 'La celda A-01 ya está en mantenimiento',
              'details': [],
            },
          },
        ),
      );

      await expectLater(
        () => repository.marcarMantenimiento('c1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CELDA_ESTADO_INVALIDO')),
      );
    });
  });

  group('volverALibre', () {
    test('éxito: devuelve la celda con estado LIBRE', () async {
      when(() => dio.patch('/celdas/c1/liberar')).thenAnswer(
        (_) async => _jsonResponse('/celdas/c1/liberar', _celdaJson(estado: 'LIBRE')),
      );

      final celda = await repository.volverALibre('c1');

      expect(celda.estado, EstadoCelda.libre);
    });

    test('409 CELDA_OCUPADA: lanza ApiException con ese code', () async {
      when(() => dio.patch('/celdas/c1/liberar')).thenThrow(
        _dioError(
          '/celdas/c1/liberar',
          statusCode: 409,
          errorBody: {
            'error': {
              'code': 'CELDA_OCUPADA',
              'message': 'La celda A-01 está ocupada y no puede liberarse manualmente',
              'details': [],
            },
          },
        ),
      );

      await expectLater(
        () => repository.volverALibre('c1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CELDA_OCUPADA')),
      );
    });

    test('409 CELDA_ESTADO_INVALIDO: lanza ApiException con ese code', () async {
      when(() => dio.patch('/celdas/c1/liberar')).thenThrow(
        _dioError(
          '/celdas/c1/liberar',
          statusCode: 409,
          errorBody: {
            'error': {'code': 'CELDA_ESTADO_INVALIDO', 'message': 'La celda A-01 ya está libre', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.volverALibre('c1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CELDA_ESTADO_INVALIDO')),
      );
    });
  });
}
