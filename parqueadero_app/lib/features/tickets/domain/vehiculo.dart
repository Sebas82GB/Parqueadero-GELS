import '../../../core/domain/tipo_vehiculo.dart';

class Vehiculo {
  const Vehiculo({
    required this.id,
    required this.placa,
    required this.tipo,
    this.propietarioNombre,
    this.propietarioTelefono,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String placa;
  final TipoVehiculo tipo;
  final String? propietarioNombre;
  final String? propietarioTelefono;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehiculo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          placa == other.placa &&
          tipo == other.tipo &&
          propietarioNombre == other.propietarioNombre &&
          propietarioTelefono == other.propietarioTelefono &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, placa, tipo, propietarioNombre, propietarioTelefono, createdAt, updatedAt);
}
