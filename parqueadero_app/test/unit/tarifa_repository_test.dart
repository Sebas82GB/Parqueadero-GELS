import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/tarifas/data/tarifa_repository_impl.dart';
import 'package:parqueadero_app/features/tarifas/domain/tarifa.dart';

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

Map<String, dynamic> _tarifaJson({
  String id = 'tar1',
  String tipoVehiculo = 'CARRO',
  int valorMinuto = 100,
  int valorPlena = 8000,
  int valorNocturna = 6000,
  int valorMes = 150000,
  String vigenteDesde = '2026-01-01T00:00:00.000Z',
  String? vigenteHasta,
}) => {
  'id': id,
  'tipoVehiculo': tipoVehiculo,
  'valorMinuto': valorMinuto,
  'valorPlena': valorPlena,
  'valorNocturna': valorNocturna,
  'valorMes': valorMes,
  'vigenteDesde': vigenteDesde,
  'vigenteHasta': vigenteHasta,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
};

void main() {
  late MockDio dio;
  late TarifaRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = TarifaRepositoryImpl(dio);
  });

  group('listarTodas', () {
    test('una sola página: hace una llamada y devuelve la lista mapeada', () async {
      when(() => dio.get('/tarifas', queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => _jsonResponse('/tarifas', {
          'data': [_tarifaJson(id: 'tar1'), _tarifaJson(id: 'tar2')],
          'meta': {'page': 1, 'perPage': 100, 'total': 2},
        }),
      );

      final tarifas = await repository.listarTodas();

      expect(tarifas, hasLength(2));
      expect(tarifas.first.id, 'tar1');
      expect(tarifas.first.tipoVehiculo, TipoVehiculo.carro);
      expect(tarifas.first.vigenteHasta, isNull);
      verify(() => dio.get('/tarifas', queryParameters: {'page': 1, 'perPage': 100})).called(1);
    });

    test('varias páginas: pagina hasta agotar el total y combina la lista', () async {
      when(() => dio.get('/tarifas', queryParameters: {'page': 1, 'perPage': 100})).thenAnswer(
        (_) async => _jsonResponse('/tarifas', {
          'data': List.generate(100, (i) => _tarifaJson(id: 'tar$i')),
          'meta': {'page': 1, 'perPage': 100, 'total': 120},
        }),
      );
      when(() => dio.get('/tarifas', queryParameters: {'page': 2, 'perPage': 100})).thenAnswer(
        (_) async => _jsonResponse('/tarifas', {
          'data': List.generate(20, (i) => _tarifaJson(id: 'tar${100 + i}')),
          'meta': {'page': 2, 'perPage': 100, 'total': 120},
        }),
      );

      final tarifas = await repository.listarTodas();

      expect(tarifas, hasLength(120));
    });

    test('error de red: lanza NetworkException', () async {
      when(() => dio.get('/tarifas', queryParameters: any(named: 'queryParameters'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/tarifas'), type: DioExceptionType.connectionError),
      );

      await expectLater(() => repository.listarTodas(), throwsA(isA<NetworkException>()));
    });
  });

  group('crear', () {
    test('éxito: envía los 4 valores y el tipo, devuelve la nueva tarifa', () async {
      when(
        () => dio.post(
          '/tarifas',
          data: {
            'tipoVehiculo': 'CARRO',
            'valorMinuto': 100,
            'valorPlena': 8000,
            'valorNocturna': 6000,
            'valorMes': 150000,
          },
        ),
      ).thenAnswer((_) async => _jsonResponse('/tarifas', _tarifaJson()));

      final tarifa = await repository.crear(
        tipoVehiculo: TipoVehiculo.carro,
        valorMinuto: 100,
        valorPlena: 8000,
        valorNocturna: 6000,
        valorMes: 150000,
      );

      expect(tarifa.id, 'tar1');
    });

    test('400 validación: lanza ApiException con ese code', () async {
      when(() => dio.post('/tarifas', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/tarifas',
          statusCode: 400,
          errorBody: {
            'error': {'code': 'VALIDATION_ERROR', 'message': 'valorMinuto debe ser un entero', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.crear(
          tipoVehiculo: TipoVehiculo.carro,
          valorMinuto: -1,
          valorPlena: 8000,
          valorNocturna: 6000,
          valorMes: 150000,
        ),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'VALIDATION_ERROR')),
      );
    });
  });

  group('cerrar', () {
    test('éxito: devuelve la tarifa con vigenteHasta asignado', () async {
      when(() => dio.post('/tarifas/tar1/cerrar')).thenAnswer(
        (_) async => _jsonResponse(
          '/tarifas/tar1/cerrar',
          _tarifaJson(vigenteHasta: '2026-02-01T00:00:00.000Z'),
        ),
      );

      final tarifa = await repository.cerrar('tar1');

      expect(tarifa.vigenteHasta, DateTime.utc(2026, 2, 1));
    });

    test('404 TARIFA_NO_ENCONTRADA: lanza ApiException con ese code', () async {
      when(() => dio.post('/tarifas/tar1/cerrar')).thenThrow(
        _dioError(
          '/tarifas/tar1/cerrar',
          statusCode: 404,
          errorBody: {
            'error': {'code': 'TARIFA_NO_ENCONTRADA', 'message': 'Tarifa no encontrada', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.cerrar('tar1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'TARIFA_NO_ENCONTRADA')),
      );
    });

    test('409 TARIFA_YA_CERRADA: lanza ApiException con ese code', () async {
      when(() => dio.post('/tarifas/tar1/cerrar')).thenThrow(
        _dioError(
          '/tarifas/tar1/cerrar',
          statusCode: 409,
          errorBody: {
            'error': {'code': 'TARIFA_YA_CERRADA', 'message': 'La tarifa ya está cerrada', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.cerrar('tar1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'TARIFA_YA_CERRADA')),
      );
    });
  });

  group('simular', () {
    test('bloques: envía los 5 campos y devuelve valorTotal', () async {
      when(
        () => dio.post(
          '/tarifas/simular',
          data: {
            'tipoVehiculo': 'CARRO',
            'valorMinuto': 100,
            'valorPlena': 20000,
            'valorNocturna': 16000,
            'duracionMinutos': 90,
          },
        ),
      ).thenAnswer(
        (_) async => _jsonResponse('/tarifas/simular', {
          'valorTotal': 9000,
          'desglose': [
            {
              'dia': 1,
              'bloqueNumero': 1,
              'inicio': '2026-01-01T13:00:00.000Z',
              'fin': '2026-01-01T14:30:00.000Z',
              'minutos': 90,
              'tipoCobro': 'PARCIAL',
              'valor': 9000,
            },
          ],
          'horaEntrada': '2026-01-01T13:00:00.000Z',
          'horaSalida': '2026-01-01T14:30:00.000Z',
        }),
      );

      final valorTotal = await repository.simular(
        tipoVehiculo: TipoVehiculo.carro,
        valorMinuto: 100,
        valorPlena: 20000,
        valorNocturna: 16000,
        duracionMinutos: 90,
      );

      expect(valorTotal, 9000);
    });

    test('tipoVehiculo OTRO: valorTotal null', () async {
      when(() => dio.post('/tarifas/simular', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse('/tarifas/simular', {
          'valorTotal': null,
          'desglose': [
            {'tipo': 'MANUAL', 'valor': null, 'motivo': 'El operador digita el valor al registrar la salida'},
          ],
          'horaEntrada': '2026-01-01T13:00:00.000Z',
          'horaSalida': '2026-01-01T14:30:00.000Z',
        }),
      );

      final valorTotal = await repository.simular(
        tipoVehiculo: TipoVehiculo.otro,
        valorMinuto: 0,
        valorPlena: 0,
        valorNocturna: 0,
        duracionMinutos: 90,
      );

      expect(valorTotal, isNull);
    });

    test('error de validación: lanza ApiException con ese code', () async {
      when(() => dio.post('/tarifas/simular', data: any(named: 'data'))).thenThrow(
        _dioError(
          '/tarifas/simular',
          statusCode: 400,
          errorBody: {
            'error': {'code': 'VALIDATION_ERROR', 'message': 'duracionMinutos debe ser mayor a 0', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.simular(
          tipoVehiculo: TipoVehiculo.carro,
          valorMinuto: 100,
          valorPlena: 20000,
          valorNocturna: 16000,
          duracionMinutos: 0,
        ),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'VALIDATION_ERROR')),
      );
    });
  });
}
