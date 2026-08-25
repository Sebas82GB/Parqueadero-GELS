import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/tipo_vehiculo.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/mensualidad.dart';
import '../domain/mensualidad_repository.dart';
import 'dtos/mensualidad_dto.dart';
import 'dtos/mensualidad_page_dto.dart';

/// Único lugar que conoce la forma de la respuesta HTTP de `/mensualidades`.
class MensualidadRepositoryImpl implements MensualidadRepository {
  MensualidadRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<MensualidadPageResult> listar({
    EstadoPagoMensualidad? estadoPago,
    String? placa,
    VigenciaMensualidad? vigencia,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/mensualidades',
        queryParameters: {
          if (estadoPago != null) 'estadoPago': estadoPago.toBackend(),
          if (placa != null && placa.isNotEmpty) 'placa': placa,
          if (vigencia != null) 'vigencia': vigencia.toBackend(),
          'page': page,
          'perPage': perPage,
        },
      );
      final pageDto = MensualidadPageDto.fromJson(response.data as Map<String, dynamic>);
      return MensualidadPageResult(
        data: pageDto.data.map((dto) => dto.toDomain()).toList(),
        page: pageDto.meta.page,
        perPage: pageDto.meta.perPage,
        total: pageDto.meta.total,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<Mensualidad> crear({
    required String placa,
    required TipoVehiculo tipoVehiculo,
    String? propietarioNombre,
    String? propietarioTelefono,
    String? celdaId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required int valorMensualidad,
  }) async {
    try {
      final response = await _dio.post(
        '/mensualidades',
        data: {
          'placa': placa,
          'tipoVehiculo': tipoVehiculo.toBackend(),
          if (propietarioNombre != null && propietarioNombre.isNotEmpty)
            'propietarioNombre': propietarioNombre,
          if (propietarioTelefono != null && propietarioTelefono.isNotEmpty)
            'propietarioTelefono': propietarioTelefono,
          if (celdaId != null) 'celdaId': celdaId,
          'fechaInicio': fechaInicio.toUtc().toIso8601String(),
          'fechaFin': fechaFin.toUtc().toIso8601String(),
          'valorMensualidad': valorMensualidad,
        },
      );
      return MensualidadDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<Mensualidad> cancelar(String id) async {
    try {
      final response = await _dio.post('/mensualidades/$id/cancelar');
      return MensualidadDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}

final mensualidadRepositoryProvider = Provider<MensualidadRepository>(
  (ref) => MensualidadRepositoryImpl(ref.watch(dioProvider)),
);
