import 'package:json_annotation/json_annotation.dart';

import '../../domain/horario.dart';

part 'horario_dto.g.dart';

/// Nunca se re-serializa hacia el backend, por eso no genera `toJson`.
@JsonSerializable(createToJson: false)
class HorarioDto {
  HorarioDto({
    required this.id,
    required this.apertura,
    required this.cierre,
    required this.vigenteDesde,
    required this.vigenteHasta,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HorarioDto.fromJson(Map<String, dynamic> json) => _$HorarioDtoFromJson(json);

  final String id;
  final String apertura;
  final String cierre;
  final String vigenteDesde;
  final String? vigenteHasta;
  final String createdAt;
  final String updatedAt;

  Horario toDomain() => Horario(
    id: id,
    apertura: apertura,
    cierre: cierre,
    vigenteDesde: DateTime.parse(vigenteDesde),
    vigenteHasta: vigenteHasta == null ? null : DateTime.parse(vigenteHasta!),
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );
}
