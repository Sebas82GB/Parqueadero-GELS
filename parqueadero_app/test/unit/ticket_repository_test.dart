import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parqueadero_app/core/domain/tipo_vehiculo.dart';
import 'package:parqueadero_app/core/network/api_exception.dart';
import 'package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart';
import 'package:parqueadero_app/features/tickets/domain/desglose_item.dart';
import 'package:parqueadero_app/features/tickets/domain/pago.dart';
import 'package:parqueadero_app/features/tickets/domain/ticket.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _jsonResponse(String path, dynamic data, {int statusCode = 200}) {
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

Map<String, dynamic> _celdaJson({String id = 'cel1', String estado = 'OCUPADA'}) => {
  'id': id,
  'codigo': 'A-01',
  'zona': 'Zona A',
  'tipoPermitido': 'CARRO',
  'estado': estado,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
};

Map<String, dynamic> _vehiculoJson({String id = 'veh1', String tipo = 'CARRO', String placa = 'ABC123'}) => {
  'id': id,
  'placa': placa,
  'tipo': tipo,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
};

Map<String, dynamic> _ticketJson({
  String id = 't1',
  String codigo = 'T-260101-ABC123',
  String estado = 'ABIERTO',
  int? valorTotal,
  List<Map<String, dynamic>>? desglose,
  Map<String, dynamic>? vehiculo,
  Map<String, dynamic>? celda,
  Map<String, dynamic>? pago,
  String? horaSalida,
}) => {
  'id': id,
  'codigo': codigo,
  'vehiculoId': vehiculo?['id'] ?? 'veh1',
  'celdaId': celda?['id'] ?? 'cel1',
  'horaEntrada': '2026-01-01T13:00:00.000Z',
  'horaSalida': horaSalida,
  'tarifaId': 'tar1',
  'valorTotal': valorTotal,
  'desglose': desglose,
  'estado': estado,
  'operadorEntradaId': 'op1',
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
  if (vehiculo != null) 'vehiculo': vehiculo,
  if (celda != null) 'celda': celda,
  if (pago != null) 'pago': pago,
};

void main() {
  late MockDio dio;
  late TicketRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = TicketRepositoryImpl(dio);
  });

  group('registrarEntrada', () {
    test('éxito: envía el body correcto y devuelve el Ticket con celda/vehiculo', () async {
      when(() => dio.post('/tickets', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse(
          '/tickets',
          _ticketJson(vehiculo: _vehiculoJson(), celda: _celdaJson()),
          statusCode: 201,
        ),
      );

      final ticket = await repository.registrarEntrada(
        placa: 'ABC123',
        tipoVehiculo: TipoVehiculo.carro,
        celdaId: 'cel1',
        propietarioNombre: 'Ana',
        propietarioTelefono: '3001234567',
      );

      expect(ticket.estado, EstadoTicket.abierto);
      expect(ticket.vehiculo?.placa, 'ABC123');
      expect(ticket.celda?.estado.name, 'ocupada');
      verify(
        () => dio.post(
          '/tickets',
          data: {
            'placa': 'ABC123',
            'tipoVehiculo': 'CARRO',
            'celdaId': 'cel1',
            'propietarioNombre': 'Ana',
            'propietarioTelefono': '3001234567',
          },
        ),
      ).called(1);
    });

    test('sin propietario: no manda esas claves', () async {
      when(() => dio.post('/tickets', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse('/tickets', _ticketJson(), statusCode: 201),
      );

      await repository.registrarEntrada(placa: 'ABC123', tipoVehiculo: TipoVehiculo.moto, celdaId: 'cel1');

      verify(
        () => dio.post('/tickets', data: {'placa': 'ABC123', 'tipoVehiculo': 'MOTO', 'celdaId': 'cel1'}),
      ).called(1);
    });

    for (final caso in [
      (404, 'CELDA_NO_ENCONTRADA'),
      (409, 'CELDA_OCUPADA'),
      (409, 'CELDA_EN_MANTENIMIENTO'),
      (409, 'VEHICULO_CON_TICKET_ABIERTO'),
      (422, 'CELDA_TIPO_INCOMPATIBLE'),
      (422, 'TARIFA_NO_VIGENTE'),
      (409, 'TICKET_CODIGO_DUPLICADO'),
      (409, 'TICKET_CONFLICTO_UNICIDAD'),
    ]) {
      test('${caso.$1} ${caso.$2}: lanza ApiException con ese code', () async {
        when(() => dio.post('/tickets', data: any(named: 'data'))).thenThrow(
          _dioError(
            '/tickets',
            statusCode: caso.$1,
            errorBody: {
              'error': {'code': caso.$2, 'message': 'mensaje del backend', 'details': []},
            },
          ),
        );

        await expectLater(
          () => repository.registrarEntrada(placa: 'ABC123', tipoVehiculo: TipoVehiculo.carro, celdaId: 'cel1'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', caso.$2)),
        );
      });
    }
  });

  group('registrarSalida', () {
    test('éxito con desglose de bloques: envía metodo y devuelve valorTotal + desglose', () async {
      when(() => dio.post('/tickets/t1/salida', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse(
          '/tickets/t1/salida',
          _ticketJson(
            estado: 'PAGADO',
            valorTotal: 9000,
            horaSalida: '2026-01-01T14:30:00.000Z',
            desglose: [
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
            vehiculo: _vehiculoJson(),
            celda: _celdaJson(estado: 'LIBRE'),
          ),
        ),
      );

      final ticket = await repository.registrarSalida('t1', metodo: MetodoPago.efectivo);

      expect(ticket.estado, EstadoTicket.pagado);
      expect(ticket.valorTotal, 9000);
      expect(ticket.desglose.single, isA<DesgloseBloque>());
      verify(() => dio.post('/tickets/t1/salida', data: {'metodo': 'EFECTIVO'})).called(1);
    });

    test('éxito con mensualidad: valorTotal 0, sin pago', () async {
      when(() => dio.post('/tickets/t1/salida', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse(
          '/tickets/t1/salida',
          _ticketJson(
            estado: 'PAGADO',
            valorTotal: 0,
            desglose: [
              {'tipo': 'MENSUALIDAD', 'valor': 0},
            ],
            vehiculo: _vehiculoJson(),
            celda: _celdaJson(estado: 'LIBRE'),
          ),
        ),
      );

      final ticket = await repository.registrarSalida('t1');

      expect(ticket.valorTotal, 0);
      expect(ticket.desglose.single, const DesgloseMensualidad());
      expect(ticket.pago, isNull);
      verify(() => dio.post('/tickets/t1/salida', data: <String, dynamic>{})).called(1);
    });

    test('éxito con valor manual (tipo OTRO): envía valorManual', () async {
      when(() => dio.post('/tickets/t1/salida', data: any(named: 'data'))).thenAnswer(
        (_) async => _jsonResponse(
          '/tickets/t1/salida',
          _ticketJson(
            estado: 'PAGADO',
            valorTotal: 15000,
            desglose: [
              {'tipo': 'MANUAL', 'valor': 15000},
            ],
            vehiculo: _vehiculoJson(tipo: 'OTRO'),
            celda: _celdaJson(estado: 'LIBRE'),
          ),
        ),
      );

      final ticket = await repository.registrarSalida('t1', metodo: MetodoPago.tarjeta, valorManual: 15000);

      expect(ticket.desglose.single, const DesgloseManual(valor: 15000));
      verify(
        () => dio.post('/tickets/t1/salida', data: {'metodo': 'TARJETA', 'valorManual': 15000}),
      ).called(1);
    });

    for (final caso in [
      (404, 'TICKET_NO_ENCONTRADO'),
      (409, 'TICKET_NO_ABIERTO'),
      (422, 'VALOR_MANUAL_REQUERIDO'),
      (422, 'METODO_PAGO_REQUERIDO'),
      (409, 'OPERADOR_SIN_TURNO_ABIERTO'),
      (409, 'TICKET_YA_TIENE_PAGO'),
    ]) {
      test('${caso.$1} ${caso.$2}: lanza ApiException con ese code', () async {
        when(() => dio.post('/tickets/t1/salida', data: any(named: 'data'))).thenThrow(
          _dioError(
            '/tickets/t1/salida',
            statusCode: caso.$1,
            errorBody: {
              'error': {'code': caso.$2, 'message': 'mensaje del backend', 'details': []},
            },
          ),
        );

        await expectLater(
          () => repository.registrarSalida('t1'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', caso.$2)),
        );
      });
    }
  });

  group('previsualizarCobro', () {
    test('éxito con desglose de bloques: parsea valorTotal y desglose', () async {
      when(() => dio.get('/tickets/t1/preview-cobro')).thenAnswer(
        (_) async => _jsonResponse('/tickets/t1/preview-cobro', {
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

      final preview = await repository.previsualizarCobro('t1');

      expect(preview.valorTotal, 9000);
      expect(preview.desglose.single, isA<DesgloseBloque>());
      expect(preview.horaEntrada, DateTime.parse('2026-01-01T13:00:00.000Z'));
      expect(preview.horaSalida, DateTime.parse('2026-01-01T14:30:00.000Z'));
    });

    test('éxito con mensualidad vigente: valorTotal 0', () async {
      when(() => dio.get('/tickets/t1/preview-cobro')).thenAnswer(
        (_) async => _jsonResponse('/tickets/t1/preview-cobro', {
          'valorTotal': 0,
          'desglose': [
            {'tipo': 'MENSUALIDAD', 'valor': 0},
          ],
          'horaEntrada': '2026-01-01T13:00:00.000Z',
          'horaSalida': '2026-01-01T14:30:00.000Z',
        }),
      );

      final preview = await repository.previsualizarCobro('t1');

      expect(preview.valorTotal, 0);
      expect(preview.desglose.single, const DesgloseMensualidad());
    });

    test('vehículo OTRO: valorTotal null y desglose con motivo', () async {
      when(() => dio.get('/tickets/t1/preview-cobro')).thenAnswer(
        (_) async => _jsonResponse('/tickets/t1/preview-cobro', {
          'valorTotal': null,
          'desglose': [
            {
              'tipo': 'MANUAL',
              'valor': null,
              'motivo': 'El operador digita el valor al registrar la salida',
            },
          ],
          'horaEntrada': '2026-01-01T13:00:00.000Z',
          'horaSalida': '2026-01-01T14:30:00.000Z',
        }),
      );

      final preview = await repository.previsualizarCobro('t1');

      expect(preview.valorTotal, isNull);
      expect(
        preview.desglose.single,
        const DesgloseManual(valor: null, motivo: 'El operador digita el valor al registrar la salida'),
      );
    });

    for (final caso in [(404, 'TICKET_NO_ENCONTRADO'), (409, 'TICKET_NO_ABIERTO')]) {
      test('${caso.$1} ${caso.$2}: lanza ApiException con ese code', () async {
        when(() => dio.get('/tickets/t1/preview-cobro')).thenThrow(
          _dioError(
            '/tickets/t1/preview-cobro',
            statusCode: caso.$1,
            errorBody: {
              'error': {'code': caso.$2, 'message': 'mensaje del backend', 'details': []},
            },
          ),
        );

        await expectLater(
          () => repository.previsualizarCobro('t1'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', caso.$2)),
        );
      });
    }
  });

  group('obtenerPorId', () {
    test('éxito: devuelve el ticket con detalle completo', () async {
      when(() => dio.get('/tickets/t1')).thenAnswer(
        (_) async => _jsonResponse(
          '/tickets/t1',
          _ticketJson(vehiculo: _vehiculoJson(), celda: _celdaJson()),
        ),
      );

      final ticket = await repository.obtenerPorId('t1');

      expect(ticket.id, 't1');
    });

    test('404 TICKET_NO_ENCONTRADO: lanza ApiException con ese code', () async {
      when(() => dio.get('/tickets/t1')).thenThrow(
        _dioError(
          '/tickets/t1',
          statusCode: 404,
          errorBody: {
            'error': {'code': 'TICKET_NO_ENCONTRADO', 'message': 'no encontrado', 'details': []},
          },
        ),
      );

      await expectLater(
        () => repository.obtenerPorId('t1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'TICKET_NO_ENCONTRADO')),
      );
    });
  });

  group('listar', () {
    test('sin filtros: manda solo page y perPage', () async {
      when(() => dio.get('/tickets', queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => _jsonResponse('/tickets', {
          'data': [_ticketJson(vehiculo: _vehiculoJson(), celda: _celdaJson())],
          'meta': {'page': 1, 'perPage': 20, 'total': 1},
        }),
      );

      final pagina = await repository.listar();

      expect(pagina.data, hasLength(1));
      expect(pagina.total, 1);
      verify(() => dio.get('/tickets', queryParameters: {'page': 1, 'perPage': 20})).called(1);
    });

    test('con filtros: arma queryParameters solo con los provistos', () async {
      when(() => dio.get('/tickets', queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => _jsonResponse('/tickets', {
          'data': <Map<String, dynamic>>[],
          'meta': {'page': 1, 'perPage': 20, 'total': 0},
        }),
      );

      await repository.listar(
        estado: EstadoTicket.abierto,
        celdaId: 'cel1',
        placa: 'ABC123',
        desde: DateTime.utc(2026, 1, 1),
        hasta: DateTime.utc(2026, 1, 31),
      );

      verify(
        () => dio.get(
          '/tickets',
          queryParameters: {
            'estado': 'ABIERTO',
            'celdaId': 'cel1',
            'placa': 'ABC123',
            'desde': '2026-01-01T00:00:00.000Z',
            'hasta': '2026-01-31T00:00:00.000Z',
            'page': 1,
            'perPage': 20,
          },
        ),
      ).called(1);
    });

    test('error de red: lanza NetworkException', () async {
      when(() => dio.get('/tickets', queryParameters: any(named: 'queryParameters'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/tickets'), type: DioExceptionType.connectionError),
      );

      await expectLater(() => repository.listar(), throwsA(isA<NetworkException>()));
    });
  });
}
