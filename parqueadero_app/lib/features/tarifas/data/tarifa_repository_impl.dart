import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/tarifa.dart';
import '../domain/tarifa_repository.dart';
import 'dtos/tarifa_dto.dart';
import 'dtos/tarifa_page_dto.dart';

/// Único lugar que conoce la forma de la respuesta HTTP de `/tarifas`.
class TarifaRepositoryImpl implements TarifaRepository {
  TarifaRepositoryImpl(this._dio);

  final Dio _dio;

  static const _perPage = 100;

  @override
  Future<List<Tarifa>> listarTodas() async {
    try {
      final dtos = <TarifaDto>[];
      var page = 1;
      while (true) {
        final response = await _dio.get(
          '/tarifas',
          queryParameters: {'page': page, 'perPage': _perPage},
        );
        final pageDto = TarifaPageDto.fromJson(response.data as Map<String, dynamic>);
        dtos.addAll(pageDto.data);
        if (page * pageDto.meta.perPage >= pageDto.meta.total) break;
        page++;
      }
      return dtos.map((dto) => dto.toDomain()).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<Tarifa> crear({
    required TipoVehiculo tipoVehiculo,
    required int valorMinuto,
    required int valorPlena,
    required int valorNocturna,
    required int valorMes,
  }) async {
    try {
      final response = await _dio.post(
        '/tarifas',
        data: {
          'tipoVehiculo': tipoVehiculo.toBackend(),
          'valorMinuto': valorMinuto,
          'valorPlena': valorPlena,
          'valorNocturna': valorNocturna,
          'valorMes': valorMes,
        },
      );
      return TarifaDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<Tarifa> cerrar(String id) async {
    try {
      final response = await _dio.post('/tarifas/$id/cerrar');
      return TarifaDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<int?> simular({
    required TipoVehiculo tipoVehiculo,
    required int valorMinuto,
    required int valorPlena,
    required int valorNocturna,
    required int duracionMinutos,
  }) async {
    try {
      final response = await _dio.post(
        '/tarifas/simular',
        data: {
          'tipoVehiculo': tipoVehiculo.toBackend(),
          'valorMinuto': valorMinuto,
          'valorPlena': valorPlena,
          'valorNocturna': valorNocturna,
          'duracionMinutos': duracionMinutos,
        },
      );
      // Sin DTO: la respuesta solo se usa por `valorTotal` (ver doc de
      // `TarifaRepository.simular`), no vale la pena modelar `desglose`
      // completo para un único campo.
      return (response.data as Map<String, dynamic>)['valorTotal'] as int?;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}

final tarifaRepositoryProvider = Provider<TarifaRepository>(
  (ref) => TarifaRepositoryImpl(ref.watch(dioProvider)),
);
