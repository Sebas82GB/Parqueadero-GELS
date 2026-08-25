// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketDto _$TicketDtoFromJson(Map<String, dynamic> json) => TicketDto(
  id: json['id'] as String,
  codigo: json['codigo'] as String,
  vehiculoId: json['vehiculoId'] as String,
  celdaId: json['celdaId'] as String,
  horaEntrada: json['horaEntrada'] as String,
  horaSalida: json['horaSalida'] as String?,
  tarifaId: json['tarifaId'] as String,
  valorTotal: (json['valorTotal'] as num?)?.toInt(),
  desglose: json['desglose'] == null
      ? const []
      : desgloseFromJson(json['desglose'] as List?),
  estado: json['estado'] as String,
  operadorEntradaId: json['operadorEntradaId'] as String,
  operadorSalidaId: json['operadorSalidaId'] as String?,
  motivoAnulacion: json['motivoAnulacion'] as String?,
  anuladoPorId: json['anuladoPorId'] as String?,
  anuladoEn: json['anuladoEn'] as String?,
  entregadoPorId: json['entregadoPorId'] as String?,
  entregadoEn: json['entregadoEn'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  vehiculo: json['vehiculo'] == null
      ? null
      : VehiculoDto.fromJson(json['vehiculo'] as Map<String, dynamic>),
  celda: json['celda'] == null
      ? null
      : CeldaDto.fromJson(json['celda'] as Map<String, dynamic>),
  pago: json['pago'] == null
      ? null
      : PagoDto.fromJson(json['pago'] as Map<String, dynamic>),
  recibo: json['recibo'] == null
      ? null
      : ReciboDto.fromJson(json['recibo'] as Map<String, dynamic>),
);
