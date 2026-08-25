import 'package:json_annotation/json_annotation.dart';

import '../../domain/turno.dart';

part 'turno_dto.g.dart';

@JsonSerializable(createToJson: false)
class TurnoDto {
  TurnoDto({
    required this.id,
    required this.operadorId,
    required this.apertura,
    this.cierre,
    required this.baseInicial,
    this.totalRecaudado,
    this.efectivoContado,
    this.efectivoEsperado,
    this.diferencia,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TurnoDto.fromJson(Map<String, dynamic> json) => _$TurnoDtoFromJson(json);

  final String id;
  final String operadorId;
  final String apertura;
  final String? cierre;
  final int baseInicial;
  final int? totalRecaudado;
  final int? efectivoContado;
  final int? efectivoEsperado;
  final int? diferencia;
  final String estado;
  final String createdAt;
  final String updatedAt;

  Turno toDomain() => Turno(
    id: id,
    operadorId: operadorId,
    apertura: DateTime.parse(apertura),
    cierre: cierre == null ? null : DateTime.parse(cierre!),
    baseInicial: baseInicial,
    totalRecaudado: totalRecaudado,
    efectivoContado: efectivoContado,
    efectivoEsperado: efectivoEsperado,
    diferencia: diferencia,
    estado: EstadoTurno.fromBackend(estado),
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );
}
