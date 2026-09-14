import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/horario.dart';
import '../domain/horario_repository.dart';
import 'dtos/horario_dto.dart';
import 'dtos/horario_page_dto.dart';

/// Único lugar que conoce la forma de la respuesta HTTP de `/horarios`.
class HorarioRepositoryImpl implements HorarioRepository {
  HorarioRepositoryImpl(this._dio);

  final Dio _dio;

  static const _perPage = 100;

  @override
  Future<List<Horario>> listarTodas() async {
    try {
      final dtos = <HorarioDto>[];
      var page = 1;
      while (true) {
        final response = await _dio.get(
          '/horarios',
          queryParameters: {'page': page, 'perPage': _perPage},
        );
        final pageDto = HorarioPageDto.fromJson(response.data as Map<String, dynamic>);
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
  Future<Horario> crear({required String apertura, required String cierre}) async {
    try {
      final response = await _dio.post('/horarios', data: {'apertura': apertura, 'cierre': cierre});
      return HorarioDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<Horario> actualizar(String id, {String? apertura, String? cierre}) async {
    try {
      final response = await _dio.patch(
        '/horarios/$id',
        data: {
          if (apertura != null) 'apertura': apertura,
          if (cierre != null) 'cierre': cierre,
        },
      );
      return HorarioDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<Horario> cerrar(String id) async {
    try {
      final response = await _dio.post('/horarios/$id/cerrar');
      return HorarioDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}

final horarioRepositoryProvider = Provider<HorarioRepository>(
  (ref) => HorarioRepositoryImpl(ref.watch(dioProvider)),
);
