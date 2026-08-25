import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/celda.dart';
import '../domain/celda_repository.dart';
import 'dtos/celda_dto.dart';
import 'dtos/celda_page_dto.dart';

/// Único lugar que conoce la forma de la respuesta HTTP de `/celdas`.
class CeldaRepositoryImpl implements CeldaRepository {
  CeldaRepositoryImpl(this._dio);

  final Dio _dio;

  static const _perPage = 100;

  @override
  Future<List<Celda>> listarTodas() async {
    try {
      final dtos = <CeldaDto>[];
      var page = 1;
      while (true) {
        final response = await _dio.get(
          '/celdas',
          queryParameters: {'page': page, 'perPage': _perPage},
        );
        final pageDto = CeldaPageDto.fromJson(response.data as Map<String, dynamic>);
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
  Future<Celda> marcarMantenimiento(String id) async {
    try {
      final response = await _dio.patch('/celdas/$id/mantenimiento');
      return CeldaDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<Celda> volverALibre(String id) async {
    try {
      final response = await _dio.patch('/celdas/$id/liberar');
      return CeldaDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}

final celdaRepositoryProvider = Provider<CeldaRepository>(
  (ref) => CeldaRepositoryImpl(ref.watch(dioProvider)),
);
