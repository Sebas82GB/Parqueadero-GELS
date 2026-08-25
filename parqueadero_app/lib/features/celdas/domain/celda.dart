import '../../../core/domain/tipo_vehiculo.dart';

export '../../../core/domain/tipo_vehiculo.dart';

enum EstadoCelda {
  libre,
  ocupada,
  mantenimiento;

  static EstadoCelda fromBackend(String value) => switch (value) {
    'LIBRE' => EstadoCelda.libre,
    'OCUPADA' => EstadoCelda.ocupada,
    'MANTENIMIENTO' => EstadoCelda.mantenimiento,
    _ => throw FormatException('estado de celda desconocido recibido del backend: $value'),
  };
}

/// Entidad de dominio. La sustitución tras una acción (mantenimiento/liberar)
/// se hace con la Celda que devuelve el propio backend, no con un mutador
/// local: no hay `copyWith` a propósito.
class Celda {
  const Celda({
    required this.id,
    required this.codigo,
    required this.zona,
    required this.tipoPermitido,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String codigo;
  final String zona;
  final TipoVehiculo tipoPermitido;
  final EstadoCelda estado;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Celda &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          codigo == other.codigo &&
          zona == other.zona &&
          tipoPermitido == other.tipoPermitido &&
          estado == other.estado &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, codigo, zona, tipoPermitido, estado, createdAt, updatedAt);
}
