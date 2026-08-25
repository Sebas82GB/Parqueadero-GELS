import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/tipo_vehiculo.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/cobro_preview.dart';
import '../domain/pago.dart';
import '../domain/ticket.dart';
import '../domain/ticket_repository.dart';
import 'dtos/cobro_preview_dto.dart';
import 'dtos/ticket_dto.dart';
import 'dtos/ticket_page_dto.dart';

/// Único lugar que conoce la forma de la respuesta HTTP de `/tickets`.
class TicketRepositoryImpl implements TicketRepository {
  TicketRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Ticket> registrarEntrada({
    required String placa,
    required TipoVehiculo tipoVehiculo,
    required String celdaId,
    String? propietarioNombre,
    String? propietarioTelefono,
  }) async {
    try {
      final response = await _dio.post(
        '/tickets',
        data: {
          'placa': placa,
          'tipoVehiculo': tipoVehiculo.toBackend(),
          'celdaId': celdaId,
          if (propietarioNombre != null && propietarioNombre.isNotEmpty)
            'propietarioNombre': propietarioNombre,
          if (propietarioTelefono != null && propietarioTelefono.isNotEmpty)
            'propietarioTelefono': propietarioTelefono,
        },
      );
      return TicketDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<Ticket> registrarSalida(String ticketId, {MetodoPago? metodo, int? valorManual}) async {
    try {
      final response = await _dio.post(
        '/tickets/$ticketId/salida',
        data: {
          if (metodo != null) 'metodo': metodo.toBackend(),
          if (valorManual != null) 'valorManual': valorManual,
        },
      );
      return TicketDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<CobroPreview> previsualizarCobro(String ticketId) async {
    try {
      final response = await _dio.get('/tickets/$ticketId/preview-cobro');
      return cobroPreviewFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<Ticket> obtenerPorId(String id) async {
    try {
      final response = await _dio.get('/tickets/$id');
      return TicketDto.fromJson(response.data as Map<String, dynamic>).toDomain();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  @override
  Future<TicketPageResult> listar({
    EstadoTicket? estado,
    String? vehiculoId,
    String? celdaId,
    String? placa,
    DateTime? desde,
    DateTime? hasta,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/tickets',
        queryParameters: {
          if (estado != null) 'estado': estado.toBackend(),
          if (vehiculoId != null) 'vehiculoId': vehiculoId,
          if (celdaId != null) 'celdaId': celdaId,
          if (placa != null && placa.isNotEmpty) 'placa': placa,
          if (desde != null) 'desde': desde.toUtc().toIso8601String(),
          if (hasta != null) 'hasta': hasta.toUtc().toIso8601String(),
          'page': page,
          'perPage': perPage,
        },
      );
      final pageDto = TicketPageDto.fromJson(response.data as Map<String, dynamic>);
      return TicketPageResult(
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

final ticketRepositoryProvider = Provider<TicketRepository>(
  (ref) => TicketRepositoryImpl(ref.watch(dioProvider)),
);
