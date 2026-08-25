// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arqueo_turno_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotalesPorMetodoDto _$TotalesPorMetodoDtoFromJson(Map<String, dynamic> json) =>
    TotalesPorMetodoDto(
      efectivo: (json['EFECTIVO'] as num).toInt(),
      tarjeta: (json['TARJETA'] as num).toInt(),
      transferencia: (json['TRANSFERENCIA'] as num).toInt(),
    );

ArqueoTurnoDto _$ArqueoTurnoDtoFromJson(Map<String, dynamic> json) =>
    ArqueoTurnoDto(
      turnoId: json['turnoId'] as String,
      operadorId: json['operadorId'] as String,
      estado: json['estado'] as String,
      apertura: json['apertura'] as String,
      cierre: json['cierre'] as String?,
      baseInicial: (json['baseInicial'] as num).toInt(),
      totalesPorMetodo: TotalesPorMetodoDto.fromJson(
        json['totalesPorMetodo'] as Map<String, dynamic>,
      ),
      totalRecaudado: (json['totalRecaudado'] as num).toInt(),
      ticketsCerrados: (json['ticketsCerrados'] as num).toInt(),
      efectivoEsperado: (json['efectivoEsperado'] as num).toInt(),
      efectivoContado: (json['efectivoContado'] as num?)?.toInt(),
      diferencia: (json['diferencia'] as num?)?.toInt(),
    );
