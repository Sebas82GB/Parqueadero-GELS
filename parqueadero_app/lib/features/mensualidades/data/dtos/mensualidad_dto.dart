import 'package:json_annotation/json_annotation.dart';

import '../../domain/mensualidad.dart';

part 'mensualidad_dto.g.dart';

/// Nunca se re-serializa hacia el backend, por eso no genera `toJson`.
@JsonSerializable(createToJson: false)
class MensualidadDto {
  MensualidadDto({
    required this.id,
    required this.vehiculoId,
    required this.celdaId,
    required this.fechaInicio,
    required this.fechaFin,
    required this.valorMensualidad,
    required this.estadoPago,
    required this.fechaPago,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MensualidadDto.fromJson(Map<String, dynamic> json) => _$MensualidadDtoFromJson(json);

  final String id;
  final String vehiculoId;
  final String? celdaId;
  final String fechaInicio;
  final String fechaFin;
  final int valorMensualidad;
  final String estadoPago;
  final String? fechaPago;
  final String createdAt;
  final String updatedAt;

  Mensualidad toDomain() => Mensualidad(
    id: id,
    vehiculoId: vehiculoId,
    celdaId: celdaId,
    fechaInicio: DateTime.parse(fechaInicio),
    fechaFin: DateTime.parse(fechaFin),
    valorMensualidad: valorMensualidad,
    estadoPago: EstadoPagoMensualidad.fromBackend(estadoPago),
    fechaPago: fechaPago == null ? null : DateTime.parse(fechaPago!),
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );
}
