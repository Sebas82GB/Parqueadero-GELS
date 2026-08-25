import 'package:json_annotation/json_annotation.dart';

import '../../domain/arqueo_turno.dart';
import '../../domain/turno.dart';

part 'arqueo_turno_dto.g.dart';

@JsonSerializable(createToJson: false)
class TotalesPorMetodoDto {
  TotalesPorMetodoDto({required this.efectivo, required this.tarjeta, required this.transferencia});

  factory TotalesPorMetodoDto.fromJson(Map<String, dynamic> json) => _$TotalesPorMetodoDtoFromJson(json);

  @JsonKey(name: 'EFECTIVO')
  final int efectivo;
  @JsonKey(name: 'TARJETA')
  final int tarjeta;
  @JsonKey(name: 'TRANSFERENCIA')
  final int transferencia;

  TotalesPorMetodo toDomain() =>
      TotalesPorMetodo(efectivo: efectivo, tarjeta: tarjeta, transferencia: transferencia);
}

@JsonSerializable(createToJson: false)
class ArqueoTurnoDto {
  ArqueoTurnoDto({
    required this.turnoId,
    required this.operadorId,
    required this.estado,
    required this.apertura,
    this.cierre,
    required this.baseInicial,
    required this.totalesPorMetodo,
    required this.totalRecaudado,
    required this.ticketsCerrados,
    required this.efectivoEsperado,
    this.efectivoContado,
    this.diferencia,
  });

  factory ArqueoTurnoDto.fromJson(Map<String, dynamic> json) => _$ArqueoTurnoDtoFromJson(json);

  final String turnoId;
  final String operadorId;
  final String estado;
  final String apertura;
  final String? cierre;
  final int baseInicial;
  final TotalesPorMetodoDto totalesPorMetodo;
  final int totalRecaudado;
  final int ticketsCerrados;
  final int efectivoEsperado;
  final int? efectivoContado;
  final int? diferencia;

  ArqueoTurno toDomain() => ArqueoTurno(
    turnoId: turnoId,
    operadorId: operadorId,
    estado: EstadoTurno.fromBackend(estado),
    apertura: DateTime.parse(apertura),
    cierre: cierre == null ? null : DateTime.parse(cierre!),
    baseInicial: baseInicial,
    totalesPorMetodo: totalesPorMetodo.toDomain(),
    totalRecaudado: totalRecaudado,
    ticketsCerrados: ticketsCerrados,
    efectivoEsperado: efectivoEsperado,
    efectivoContado: efectivoContado,
    diferencia: diferencia,
  );
}
