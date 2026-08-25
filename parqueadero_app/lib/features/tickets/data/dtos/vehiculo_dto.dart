import 'package:json_annotation/json_annotation.dart';

import '../../../../core/domain/tipo_vehiculo.dart';
import '../../domain/vehiculo.dart';

part 'vehiculo_dto.g.dart';

@JsonSerializable(createToJson: false)
class VehiculoDto {
  VehiculoDto({
    required this.id,
    required this.placa,
    required this.tipo,
    this.propietarioNombre,
    this.propietarioTelefono,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehiculoDto.fromJson(Map<String, dynamic> json) => _$VehiculoDtoFromJson(json);

  final String id;
  final String placa;
  final String tipo;
  final String? propietarioNombre;
  final String? propietarioTelefono;
  final String createdAt;
  final String updatedAt;

  Vehiculo toDomain() => Vehiculo(
    id: id,
    placa: placa,
    tipo: TipoVehiculo.fromBackend(tipo),
    propietarioNombre: propietarioNombre,
    propietarioTelefono: propietarioTelefono,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );
}
