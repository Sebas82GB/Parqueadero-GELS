// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tarifa_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TarifaDto _$TarifaDtoFromJson(Map<String, dynamic> json) => TarifaDto(
  id: json['id'] as String,
  tipoVehiculo: json['tipoVehiculo'] as String,
  valorMinuto: (json['valorMinuto'] as num).toInt(),
  valorPlena: (json['valorPlena'] as num).toInt(),
  valorNocturna: (json['valorNocturna'] as num).toInt(),
  valorMes: (json['valorMes'] as num).toInt(),
  vigenteDesde: json['vigenteDesde'] as String,
  vigenteHasta: json['vigenteHasta'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);
