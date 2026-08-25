import 'package:json_annotation/json_annotation.dart';

import '../../domain/pago.dart';

part 'pago_dto.g.dart';

@JsonSerializable(createToJson: false)
class PagoDto {
  PagoDto({
    required this.id,
    this.ticketId,
    this.mensualidadId,
    required this.monto,
    required this.metodo,
    required this.turnoId,
    required this.fecha,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PagoDto.fromJson(Map<String, dynamic> json) => _$PagoDtoFromJson(json);

  final String id;
  final String? ticketId;
  final String? mensualidadId;
  final int monto;
  final String metodo;
  final String turnoId;
  final String fecha;
  final String estado;
  final String createdAt;
  final String updatedAt;

  Pago toDomain() => Pago(
    id: id,
    ticketId: ticketId,
    mensualidadId: mensualidadId,
    monto: monto,
    metodo: MetodoPago.fromBackend(metodo),
    turnoId: turnoId,
    fecha: DateTime.parse(fecha),
    estado: EstadoPago.fromBackend(estado),
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );
}
