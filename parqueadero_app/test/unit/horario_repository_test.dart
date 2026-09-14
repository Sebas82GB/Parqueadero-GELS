import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/horarios/data/horario_repository_impl.dart';

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

Map<String, dynamic> _horarioJson({
  String id = 'hor1',
  String apertura = '08:00',
  String cierre = '21:00',
  String vigenteDesde = '2026-01-01T00:00:00.000Z',
  String? vigenteHasta,
}) => {
  'id': id,
  'apertura': apertura,
  'cierre': cierre,
  'vigenteDesde': vigenteDesde,
  'vigenteHasta': vigenteHasta,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
};

void main() {
  late MockDio dio;
  late HorarioRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = HorarioRepositoryImpl(dio);
  });

  group('listarTodas', () {
    test('una sola página: hace una llamada y devuelve la lista mapeada', () async {
      when(() => dio.get('/horarios', queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => _jsonResponse('/horarios', {
          'data': [_horarioJson(id: 'hor1'), _horarioJson(id: 'hor2')],
          'meta': {'page': 1, 'perPage': 100, 'total': 2},
        }),
      );

      final horarios = await repository.listarTodas();

      expect(horarios, hasLength(2));
      expect(horarios.first.id, 'hor1');
      expect(horarios.first.apertura, '08:00');
      expect(horarios.first.cierre, '21:00');
      expect(horarios.first.vigenteHasta, isNull);
      verify(() => dio.get('/horarios', queryParameters: {'page': 1, 'perPage': 100})).called(1);
    });

    test('varias páginas: pagina hasta agotar el total y combina la lista', () async {
      when(() => dio.get('/horarios', queryParameters: {'page': 1, 'perPage': 100})).thenAnswer(
        (_) async => _jsonResponse('/horarios', {
          'data': List.generate(100, (i) => _horarioJson(id: 'hor$i')),
          'meta': {'page': 1, 'perPage': 100, 'total': 120},
        }),
      );
      when(() => dio.get('/horarios', queryParameters: {'page': 2, 'perPage': 100})).thenAnswer(
        (_) async => _jsonResponse('/horarios', {
          'data': List.generate(20, (i) => _horarioJson(id: 'hor${100 + i}')),
          'meta': {'page': 2, 'perPage': 100, 'total': 120},
        }),
      );

      final horarios = await repository.listarTodas();

      expect(horarios, hasLength(120));
    });

    test('error de red: lanza NetworkException', () async {
      when(() => dio.get('/horarios', queryParameters: any(named: 'queryParameters'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/horarios'), type: DioExceptionType.connectionError),
      );

      await expectLater(() => repository.listarTodas(), throwsA(isA<NetworkException>()));
    });
  });

  group('crear', () {
    test('éxito: envía apertura y cierre, devuelve el nuevo horario', () async {
      when(
        () => dio.post('/horarios', data: {'apertura': '08:00', 'cierre': '21:00'}),
      ).thenAnswer((_) async => _jsonResponse('/horarios', _horarioJson()));

      final horario = await repository.crear(apertura: '08:00', cierre: '21:00');

      expect(horario.id, 'hor1');
      expect(horario.apertura, '08:00');
      expect(horario.cierre, '21:00');
    });

    test('400 validación: lanza ApiException con ese code', () async {
      when(() => dio.post('/horarios', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/horarios',
          statusCode: 400,
          errorBody: {
            'error': {'code': 'VALIDATION_ERROR', 'message': 'cierre debe ser posterior a apertura', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.crear(apertura: '21:00', cierre: '08:00'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'VALIDATION_ERROR')),
      );
    });
  });

  group('actualizar', () {
    test('éxito: envía solo los campos no nulos, devuelve el horario actualizado', () async {
      when(
        () => dio.patch('/horarios/hor1', data: {'apertura': '07:00'}),
      ).thenAnswer((_) async => _jsonResponse('/horarios/hor1', _horarioJson(apertura: '07:00')));

      final horario = await repository.actualizar('hor1', apertura: '07:00');

      expect(horario.apertura, '07:00');
      verify(() => dio.patch('/horarios/hor1', data: {'apertura': '07:00'})).called(1);
    });

    test('ambos campos: incluye apertura y cierre', () async {
      when(
        () => dio.patch('/horarios/hor1', data: {'apertura': '07:00', 'cierre': '22:00'}),
      ).thenAnswer(
        (_) async => _jsonResponse('/horarios/hor1', _horarioJson(apertura: '07:00', cierre: '22:00')),
      );

      final horario = await repository.actualizar('hor1', apertura: '07:00', cierre: '22:00');

      expect(horario.apertura, '07:00');
      expect(horario.cierre, '22:00');
      verify(() => dio.patch('/horarios/hor1', data: {'apertura': '07:00', 'cierre': '22:00'})).called(1);
    });

    test('400 VALIDATION_ERROR (body vacío): lanza ApiException con ese code', () async {
      when(() => dio.patch('/horarios/hor1', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/horarios/hor1',
          statusCode: 400,
          errorBody: {
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Debe incluir al menos un campo para actualizar',
              'details': [],
            },
          },
        ),
      );

      await expectLater(
        () => repository.actualizar('hor1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'VALIDATION_ERROR')),
      );
    });

    test('409 HORARIO_CON_TICKETS_ASOCIADOS: lanza ApiException con ese code', () async {
      when(() => dio.patch('/horarios/hor1', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/horarios/hor1',
          statusCode: 409,
          errorBody: {
            'error': {
              'code': 'HORARIO_CON_TICKETS_ASOCIADOS',
              'message': 'No se puede editar un horario que ya tiene tickets asociados',
              'details': [],
            },
          },
        ),
      );

      await expectLater(
        () => repository.actualizar('hor1', apertura: '07:00'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'HORARIO_CON_TICKETS_ASOCIADOS')),
      );
    });

    test('422 HORARIO_RANGO_INVALIDO: lanza ApiException con ese code', () async {
      when(() => dio.patch('/horarios/hor1', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/horarios/hor1',
          statusCode: 422,
          errorBody: {
            'error': {
              'code': 'HORARIO_RANGO_INVALIDO',
              'message': 'El cierre debe ser posterior a la apertura',
              'details': [],
            },
          },
        ),
      );

      await expectLater(
        () => repository.actualizar('hor1', cierre: '05:00'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'HORARIO_RANGO_INVALIDO')),
      );
    });
  });

  group('cerrar', () {
    test('éxito: devuelve el horario con vigenteHasta asignado', () async {
      when(() => dio.post('/horarios/hor1/cerrar')).thenAnswer(
        (_) async => _jsonResponse(
          '/horarios/hor1/cerrar',
          _horarioJson(vigenteHasta: '2026-02-01T00:00:00.000Z'),
        ),
      );

      final horario = await repository.cerrar('hor1');

      expect(horario.vigenteHasta, DateTime.utc(2026, 2, 1));
    });

    test('404 HORARIO_NO_ENCONTRADO: lanza ApiException con ese code', () async {
      when(() => dio.post('/horarios/hor1/cerrar')).thenThrow(
        _dioError(
          '/horarios/hor1/cerrar',
          statusCode: 404,
          errorBody: {
            'error': {'code': 'HORARIO_NO_ENCONTRADO', 'message': 'Horario no encontrado', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.cerrar('hor1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'HORARIO_NO_ENCONTRADO')),
      );
    });

    test('409 HORARIO_YA_CERRADO: lanza ApiException con ese code', () async {
      when(() => dio.post('/horarios/hor1/cerrar')).thenThrow(
        _dioError(
          '/horarios/hor1/cerrar',
          statusCode: 409,
          errorBody: {
            'error': {'code': 'HORARIO_YA_CERRADO', 'message': 'El horario ya está cerrado', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.cerrar('hor1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'HORARIO_YA_CERRADO')),
      );
    });
  });
}
