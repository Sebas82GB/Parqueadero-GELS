// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turno_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TurnoDto _$TurnoDtoFromJson(Map<String, dynamic> json) => TurnoDto(
  id: json['id'] as String,
  operadorId: json['operadorId'] as String,
  apertura: json['apertura'] as String,
  cierre: json['cierre'] as String?,
  baseInicial: (json['baseInicial'] as num).toInt(),
  totalRecaudado: (json['totalRecaudado'] as num?)?.toInt(),
  efectivoContado: (json['efectivoContado'] as num?)?.toInt(),
  efectivoEsperado: (json['efectivoEsperado'] as num?)?.toInt(),
  diferencia: (json['diferencia'] as num?)?.toInt(),
  estado: json['estado'] as String,
  validadoPorId: json['validadoPorId'] as String?,
  validadoEn: json['validadoEn'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);
