import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/turnos/data/turno_repository_impl.dart';
import 'package:parqueadero_app/features/turnos/domain/turno.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _jsonResponse(String path, Map<String, dynamic> data, {int statusCode = 201}) {
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

Map<String, dynamic> _turnoJson({
  String estado = 'ABIERTO',
  String? validadoPorId,
  String? validadoEn,
}) => {
  'id': 'tur1',
  'operadorId': 'op1',
  'apertura': '2026-01-01T06:00:00.000Z',
  'cierre': null,
  'baseInicial': 50000,
  'totalRecaudado': null,
  'estado': estado,
  'validadoPorId': validadoPorId,
  'validadoEn': validadoEn,
  'createdAt': '2026-01-01T06:00:00.000Z',
  'updatedAt': '2026-01-01T06:00:00.000Z',
};

Map<String, dynamic> _arqueoJson({
  String estado = 'CERRADO',
  int? efectivoContado = 15000,
  int? diferencia = 0,
  String? validadoPorId,
  String? validadoEn,
}) => {
  'turnoId': 'tur1',
  'operadorId': 'op1',
  'estado': estado,
  'apertura': '2026-01-01T06:00:00.000Z',
  'cierre': estado == 'ABIERTO' ? null : '2026-01-01T14:00:00.000Z',
  'baseInicial': 50000,
  'totalesPorMetodo': {'EFECTIVO': 15000, 'TARJETA': 20000, 'TRANSFERENCIA': 0},
  'totalRecaudado': 35000,
  'ticketsCerrados': 4,
  'efectivoEsperado': 65000,
  'efectivoContado': efectivoContado,
  'diferencia': diferencia,
  'validadoPorId': validadoPorId,
  'validadoEn': validadoEn,
};

void main() {
  late MockDio dio;
  late TurnoRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = TurnoRepositoryImpl(dio);
  });

  test('éxito: envía baseInicial y devuelve el Turno abierto', () async {
    when(() => dio.post('/turnos', data: any(named: 'data'))).thenAnswer(
      (_) async => _jsonResponse('/turnos', _turnoJson()),
    );

    final turno = await repository.abrir(50000);

    expect(turno.baseInicial, 50000);
    verify(() => dio.post('/turnos', data: {'baseInicial': 50000})).called(1);
  });

  test('sin baseInicial: no manda ese campo, el backend usa la automática', () async {
    when(() => dio.post('/turnos', data: any(named: 'data'))).thenAnswer(
      (_) async => _jsonResponse('/turnos', _turnoJson()),
    );

    await repository.abrir();

    verify(() => dio.post('/turnos', data: <String, dynamic>{})).called(1);
  });

  test('422: ninguna baseInicial disponible', () async {
    when(() => dio.post('/turnos', data: any(named: 'data'))).thenThrow(
      _dioError(
        '/turnos',
        statusCode: 422,
        errorBody: {
          'error': {
            'code': 'BASE_INICIAL_NO_CONFIGURADA',
            'message': 'Ningún administrador ha configurado la baseInicial para apertura automática',
            'details': [],
          },
        },
      ),
    );

    await expectLater(
      () => repository.abrir(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'BASE_INICIAL_NO_CONFIGURADA')),
    );
  });

  test('409: ya tiene un turno abierto', () async {
    when(() => dio.post('/turnos', data: any(named: 'data'))).thenThrow(
      _dioError(
        '/turnos',
        statusCode: 409,
        errorBody: {
          'error': {'code': 'TURNO_YA_ABIERTO', 'message': 'Ya tiene un turno abierto', 'details': []},
        },
      ),
    );

    await expectLater(
      () => repository.abrir(50000),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'TURNO_YA_ABIERTO')),
    );
  });

  test('400: baseInicial inválido', () async {
    when(() => dio.post('/turnos', data: any(named: 'data'))).thenThrow(
      _dioError(
        '/turnos',
        statusCode: 400,
        errorBody: {
          'error': {'code': 'VALIDATION_ERROR', 'message': 'baseInicial no puede ser negativo', 'details': []},
        },
      ),
    );

    await expectLater(() => repository.abrir(-1), throwsA(isA<ApiException>()));
  });

  group('cerrar', () {
    test('cuadre exacto: envía efectivoContado y mapea el arqueo completo', () async {
      when(() => dio.post('/turnos/tur1/cierre', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse('/turnos/tur1/cierre', _arqueoJson(), statusCode: 200),
      );

      final arqueo = await repository.cerrar('tur1', 65000);

      expect(arqueo.diferencia, 0);
      expect(arqueo.totalesPorMetodo.efectivo, 15000);
      expect(arqueo.totalesPorMetodo.tarjeta, 20000);
      expect(arqueo.ticketsCerrados, 4);
      verify(() => dio.post('/turnos/tur1/cierre', data: {'efectivoContado': 65000})).called(1);
    });

    test('sobrante: mapea diferencia positiva', () async {
      when(() => dio.post('/turnos/tur1/cierre', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse(
          '/turnos/tur1/cierre',
          _arqueoJson(efectivoContado: 70000, diferencia: 5000),
          statusCode: 200,
        ),
      );

      final arqueo = await repository.cerrar('tur1', 70000);

      expect(arqueo.diferencia, 5000);
    });

    test('faltante: mapea diferencia negativa', () async {
      when(() => dio.post('/turnos/tur1/cierre', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse(
          '/turnos/tur1/cierre',
          _arqueoJson(efectivoContado: 60000, diferencia: -5000),
          statusCode: 200,
        ),
      );

      final arqueo = await repository.cerrar('tur1', 60000);

      expect(arqueo.diferencia, -5000);
    });

    test('409: turno ya cerrado', () async {
      when(() => dio.post('/turnos/tur1/cierre', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/turnos/tur1/cierre',
          statusCode: 409,
          errorBody: {
            'error': {'code': 'CONFLICT', 'message': 'El turno ya está cerrado', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.cerrar('tur1', 65000),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CONFLICT')),
      );
    });

    test('403: no es el dueño ni ADMIN', () async {
      when(() => dio.post('/turnos/tur1/cierre', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/turnos/tur1/cierre',
          statusCode: 403,
          errorBody: {
            'error': {'code': 'FORBIDDEN', 'message': 'No tiene permisos sobre este turno', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.cerrar('tur1', 65000),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'FORBIDDEN')),
      );
    });

    test('404: turno no encontrado', () async {
      when(() => dio.post('/turnos/tur1/cierre', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/turnos/tur1/cierre',
          statusCode: 404,
          errorBody: {
            'error': {'code': 'NOT_FOUND', 'message': 'Turno no encontrado', 'details': []},
          },
        ),
      );

      await expectLater(() => repository.cerrar('tur1', 65000), throwsA(isA<ApiException>()));
    });
  });

  group('obtenerArqueo', () {
    test('turno abierto: efectivoContado y diferencia llegan en null', () async {
      when(() => dio.get('/turnos/tur1/arqueo')).thenAnswer(
        (_) async => _jsonResponse(
          '/turnos/tur1/arqueo',
          _arqueoJson(estado: 'ABIERTO', efectivoContado: null, diferencia: null),
          statusCode: 200,
        ),
      );

      final arqueo = await repository.obtenerArqueo('tur1');

      expect(arqueo.efectivoContado, isNull);
      expect(arqueo.diferencia, isNull);
      expect(arqueo.cierre, isNull);
    });

    test('turno cerrado: trae los valores finales', () async {
      when(() => dio.get('/turnos/tur1/arqueo')).thenAnswer(
        (_) async => _jsonResponse('/turnos/tur1/arqueo', _arqueoJson(), statusCode: 200),
      );

      final arqueo = await repository.obtenerArqueo('tur1');

      expect(arqueo.efectivoContado, 15000);
      expect(arqueo.cierre, isNotNull);
    });

    test('404: turno no encontrado', () async {
      when(() => dio.get('/turnos/tur1/arqueo')).thenThrow(
        _dioError(
          '/turnos/tur1/arqueo',
          statusCode: 404,
          errorBody: {
            'error': {'code': 'NOT_FOUND', 'message': 'Turno no encontrado', 'details': []},
          },
        ),
      );

      await expectLater(() => repository.obtenerArqueo('tur1'), throwsA(isA<ApiException>()));
    });

    test('CERRADO_PENDIENTE_ARQUEO: mapea el estado y deja validadoPorId/validadoEn en null', () async {
      when(() => dio.get('/turnos/tur1/arqueo')).thenAnswer(
        (_) async => _jsonResponse(
          '/turnos/tur1/arqueo',
          _arqueoJson(estado: 'CERRADO_PENDIENTE_ARQUEO', efectivoContado: null, diferencia: null),
          statusCode: 200,
        ),
      );

      final arqueo = await repository.obtenerArqueo('tur1');

      expect(arqueo.estado, EstadoTurno.cerradoPendienteArqueo);
      expect(arqueo.efectivoContado, isNull);
      expect(arqueo.validadoPorId, isNull);
      expect(arqueo.validadoEn, isNull);
    });
  });

  group('completarArqueo', () {
    test('éxito: envía efectivoContado y mapea el arqueo con validadoPorId/validadoEn', () async {
      when(() => dio.post('/turnos/tur1/completar-arqueo', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse(
          '/turnos/tur1/completar-arqueo',
          _arqueoJson(validadoPorId: 'admin1', validadoEn: '2026-01-01T14:05:00.000Z'),
          statusCode: 200,
        ),
      );

      final arqueo = await repository.completarArqueo('tur1', 65000);

      expect(arqueo.estado, EstadoTurno.cerrado);
      expect(arqueo.validadoPorId, 'admin1');
      expect(arqueo.validadoEn, DateTime.parse('2026-01-01T14:05:00.000Z'));
      verify(
        () => dio.post('/turnos/tur1/completar-arqueo', data: {'efectivoContado': 65000}),
      ).called(1);
    });

    test('403: quien llama no es ADMIN', () async {
      when(() => dio.post('/turnos/tur1/completar-arqueo', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/turnos/tur1/completar-arqueo',
          statusCode: 403,
          errorBody: {
            'error': {
              'code': 'TURNO_ARQUEO_SOLO_ADMIN',
              'message': 'Solo un administrador puede completar el arqueo',
              'details': [],
            },
          },
        ),
      );

      await expectLater(
        () => repository.completarArqueo('tur1', 65000),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'TURNO_ARQUEO_SOLO_ADMIN')),
      );
    });

    test('409: el turno no está pendiente de arqueo', () async {
      when(() => dio.post('/turnos/tur1/completar-arqueo', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/turnos/tur1/completar-arqueo',
          statusCode: 409,
          errorBody: {
            'error': {
              'code': 'TURNO_NO_PENDIENTE_ARQUEO',
              'message': 'El turno no está pendiente de arqueo',
              'details': [],
            },
          },
        ),
      );

      await expectLater(
        () => repository.completarArqueo('tur1', 65000),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'TURNO_NO_PENDIENTE_ARQUEO')),
      );
    });

    test('404: turno no encontrado', () async {
      when(() => dio.post('/turnos/tur1/completar-arqueo', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/turnos/tur1/completar-arqueo',
          statusCode: 404,
          errorBody: {
            'error': {'code': 'NOT_FOUND', 'message': 'Turno no encontrado', 'details': []},
          },
        ),
      );

      await expectLater(() => repository.completarArqueo('tur1', 65000), throwsA(isA<ApiException>()));
    });
  });

  group('listar', () {
    test('arma los query params y mapea la página', () async {
      when(
        () => dio.get('/turnos', queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => _jsonResponse('/turnos', {
          'data': [_turnoJson(), _turnoJson(estado: 'CERRADO')],
          'meta': {'page': 1, 'perPage': 20, 'total': 2},
        }, statusCode: 200),
      );

      final pagina = await repository.listar(
        operadorId: 'op1',
        estado: EstadoTurno.abierto,
        desde: DateTime.utc(2026, 1, 1),
        hasta: DateTime.utc(2026, 1, 31),
      );

      expect(pagina.data, hasLength(2));
      expect(pagina.total, 2);
      verify(
        () => dio.get(
          '/turnos',
          queryParameters: {
            'operadorId': 'op1',
            'estado': 'ABIERTO',
            'desde': '2026-01-01T00:00:00.000Z',
            'hasta': '2026-01-31T00:00:00.000Z',
            'page': 1,
            'perPage': 20,
          },
        ),
      ).called(1);
    });

    test('sin filtros: solo manda page y perPage', () async {
      when(
        () => dio.get('/turnos', queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => _jsonResponse('/turnos', {
          'data': <dynamic>[],
          'meta': {'page': 1, 'perPage': 20, 'total': 0},
        }, statusCode: 200),
      );

      await repository.listar();

      verify(() => dio.get('/turnos', queryParameters: {'page': 1, 'perPage': 20})).called(1);
    });

    test('mapea validadoPorId y validadoEn de un turno con arqueo ya completado', () async {
      when(
        () => dio.get('/turnos', queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => _jsonResponse('/turnos', {
          'data': [
            _turnoJson(
              estado: 'CERRADO',
              validadoPorId: 'admin1',
              validadoEn: '2026-01-01T14:05:00.000Z',
            ),
          ],
          'meta': {'page': 1, 'perPage': 20, 'total': 1},
        }, statusCode: 200),
      );

      final pagina = await repository.listar();

      expect(pagina.data.single.validadoPorId, 'admin1');
      expect(pagina.data.single.validadoEn, DateTime.parse('2026-01-01T14:05:00.000Z'));
    });

    test('validadoPorId y validadoEn en null: no llegan del backend', () async {
      when(
        () => dio.get('/turnos', queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => _jsonResponse('/turnos', {
          'data': [_turnoJson()],
          'meta': {'page': 1, 'perPage': 20, 'total': 1},
        }, statusCode: 200),
      );

      final pagina = await repository.listar();

      expect(pagina.data.single.validadoPorId, isNull);
      expect(pagina.data.single.validadoEn, isNull);
    });
  });
}
