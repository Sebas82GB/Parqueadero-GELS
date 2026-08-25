// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pago_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PagoDto _$PagoDtoFromJson(Map<String, dynamic> json) => PagoDto(
  id: json['id'] as String,
  ticketId: json['ticketId'] as String?,
  mensualidadId: json['mensualidadId'] as String?,
  monto: (json['monto'] as num).toInt(),
  metodo: json['metodo'] as String,
  turnoId: json['turnoId'] as String,
  fecha: json['fecha'] as String,
  estado: json['estado'] as String,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);
