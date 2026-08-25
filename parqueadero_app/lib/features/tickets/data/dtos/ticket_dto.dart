import 'package:json_annotation/json_annotation.dart';

import '../../../celdas/data/dtos/celda_dto.dart';
import '../../domain/desglose_item.dart';
import '../../domain/ticket.dart';
import 'desglose_item_dto.dart';
import 'pago_dto.dart';
import 'recibo_dto.dart';
import 'vehiculo_dto.dart';

part 'ticket_dto.g.dart';

/// El campo `tarifa` que puede venir en el JSON no se declara acá a
/// propósito: la app nunca necesita mostrarla, y json_serializable ignora
/// sin problema las claves del JSON que no tienen un field correspondiente.
@JsonSerializable(createToJson: false)
class TicketDto {
  TicketDto({
    required this.id,
    required this.codigo,
    required this.vehiculoId,
    required this.celdaId,
    required this.horaEntrada,
    this.horaSalida,
    required this.tarifaId,
    this.valorTotal,
    this.desglose = const [],
    required this.estado,
    required this.operadorEntradaId,
    this.operadorSalidaId,
    this.motivoAnulacion,
    this.anuladoPorId,
    this.anuladoEn,
    this.entregadoPorId,
    this.entregadoEn,
    required this.createdAt,
    required this.updatedAt,
    this.vehiculo,
    this.celda,
    this.pago,
    this.recibo,
  });

  factory TicketDto.fromJson(Map<String, dynamic> json) => _$TicketDtoFromJson(json);

  final String id;
  final String codigo;
  final String vehiculoId;
  final String celdaId;
  final String horaEntrada;
  final String? horaSalida;
  final String tarifaId;
  final int? valorTotal;
  @JsonKey(fromJson: desgloseFromJson)
  final List<DesgloseItem> desglose;
  final String estado;
  final String operadorEntradaId;
  final String? operadorSalidaId;
  final String? motivoAnulacion;
  final String? anuladoPorId;
  final String? anuladoEn;
  final String? entregadoPorId;
  final String? entregadoEn;
  final String createdAt;
  final String updatedAt;
  final VehiculoDto? vehiculo;
  final CeldaDto? celda;
  final PagoDto? pago;
  final ReciboDto? recibo;

  Ticket toDomain() => Ticket(
    id: id,
    codigo: codigo,
    vehiculoId: vehiculoId,
    celdaId: celdaId,
    horaEntrada: DateTime.parse(horaEntrada),
    horaSalida: horaSalida == null ? null : DateTime.parse(horaSalida!),
    tarifaId: tarifaId,
    valorTotal: valorTotal,
    desglose: desglose,
    estado: EstadoTicket.fromBackend(estado),
    operadorEntradaId: operadorEntradaId,
    operadorSalidaId: operadorSalidaId,
    motivoAnulacion: motivoAnulacion,
    anuladoPorId: anuladoPorId,
    anuladoEn: anuladoEn == null ? null : DateTime.parse(anuladoEn!),
    entregadoPorId: entregadoPorId,
    entregadoEn: entregadoEn == null ? null : DateTime.parse(entregadoEn!),
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
    vehiculo: vehiculo?.toDomain(),
    celda: celda?.toDomain(),
    pago: pago?.toDomain(),
    recibo: recibo?.toDomain(),
  );
}
