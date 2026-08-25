// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mensualidad_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MensualidadDto _$MensualidadDtoFromJson(Map<String, dynamic> json) =>
    MensualidadDto(
      id: json['id'] as String,
      vehiculoId: json['vehiculoId'] as String,
      celdaId: json['celdaId'] as String?,
      fechaInicio: json['fechaInicio'] as String,
      fechaFin: json['fechaFin'] as String,
      valorMensualidad: (json['valorMensualidad'] as num).toInt(),
      estadoPago: json['estadoPago'] as String,
      fechaPago: json['fechaPago'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
