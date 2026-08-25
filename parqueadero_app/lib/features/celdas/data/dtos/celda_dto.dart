import 'package:json_annotation/json_annotation.dart';

import '../../domain/celda.dart';

part 'celda_dto.g.dart';

/// Nunca se re-serializa hacia el backend, por eso no genera `toJson`.
@JsonSerializable(createToJson: false)
class CeldaDto {
  CeldaDto({
    required this.id,
    required this.codigo,
    required this.zona,
    required this.tipoPermitido,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CeldaDto.fromJson(Map<String, dynamic> json) => _$CeldaDtoFromJson(json);

  final String id;
  final String codigo;
  final String zona;
  final String tipoPermitido;
  final String estado;
  final String createdAt;
  final String updatedAt;

  Celda toDomain() => Celda(
    id: id,
    codigo: codigo,
    zona: zona,
    tipoPermitido: TipoVehiculo.fromBackend(tipoPermitido),
    estado: EstadoCelda.fromBackend(estado),
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );
}
