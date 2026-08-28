import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/arqueo_turno.dart';
import '../domain/turno.dart';
import '../domain/turno_repository.dart';
import 'dtos/arqueo_turno_dto.dart';
import 'dtos/turno_dto.dart';
import 'dtos/turno_page_dto.dart';

class TurnoRepositoryImpl implements TurnoRepository {
  TurnoRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Turno> abrir([int? baseInicial]) async {
    try {
      final response = await _dio.post(
        '/turnos',
        data: {if (baseInicial != null) 'baseInicial': baseInicial},
      );
      return TurnoDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<ArqueoTurno> cerrar(String turnoId, int efectivoContado) async {
    try {
      final response = await _dio.post(
        '/turnos/$turnoId/cierre',
        data: {'efectivoContado': efectivoContado},
      );
      return ArqueoTurnoDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<ArqueoTurno> obtenerArqueo(String turnoId) async {
    try {
      final response = await _dio.get('/turnos/$turnoId/arqueo');
      return ArqueoTurnoDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<ArqueoTurno> completarArqueo(String turnoId, int efectivoContado) async {
    try {
      final response = await _dio.post(
        '/turnos/$turnoId/completar-arqueo',
        data: {'efectivoContado': efectivoContado},
      );
      return ArqueoTurnoDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<TurnoPageResult> listar({
    String? operadorId,
    EstadoTurno? estado,
    DateTime? desde,
    DateTime? hasta,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/turnos',
        queryParameters: {
          if (operadorId != null) 'operadorId': operadorId,
          if (estado != null) 'estado': estado.toBackend(),
          if (desde != null) 'desde': desde.toUtc().toIso8601String(),
          if (hasta != null) 'hasta': hasta.toUtc().toIso8601String(),
          'page': page,
          'perPage': perPage,
        },
      );
      final pageDto = TurnoPageDto.fromJson(response.data as Map<String, dynamic>);
      return TurnoPageResult(
        data: pageDto.data.map((dto) => dto.toDomain()).toList(),
        page: pageDto.meta.page,
        perPage: pageDto.meta.perPage,
        total: pageDto.meta.total,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}

final turnoRepositoryProvider = Provider<TurnoRepository>(
  (ref) => TurnoRepositoryImpl(ref.watch(dioProvider)),
);
