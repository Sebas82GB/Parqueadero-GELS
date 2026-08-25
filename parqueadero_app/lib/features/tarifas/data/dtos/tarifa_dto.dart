import 'package:json_annotation/json_annotation.dart';

import '../../domain/tarifa.dart';

part 'tarifa_dto.g.dart';

/// Nunca se re-serializa hacia el backend, por eso no genera `toJson`.
@JsonSerializable(createToJson: false)
class TarifaDto {
  TarifaDto({
    required this.id,
    required this.tipoVehiculo,
    required this.valorMinuto,
    required this.valorPlena,
    required this.valorNocturna,
    required this.valorMes,
    required this.vigenteDesde,
    required this.vigenteHasta,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TarifaDto.fromJson(Map<String, dynamic> json) => _$TarifaDtoFromJson(json);

  final String id;
  final String tipoVehiculo;
  final int valorMinuto;
  final int valorPlena;
  final int valorNocturna;
  final int valorMes;
  final String vigenteDesde;
  final String? vigenteHasta;
  final String createdAt;
  final String updatedAt;

  Tarifa toDomain() => Tarifa(
    id: id,
    tipoVehiculo: TipoVehiculo.fromBackend(tipoVehiculo),
    valorMinuto: valorMinuto,
    valorPlena: valorPlena,
    valorNocturna: valorNocturna,
    valorMes: valorMes,
    vigenteDesde: DateTime.parse(vigenteDesde),
    vigenteHasta: vigenteHasta == null ? null : DateTime.parse(vigenteHasta!),
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );
}
