enum RolUsuario {
  admin,
  operador;

  static RolUsuario fromBackend(String value) => switch (value) {
    'ADMIN' => RolUsuario.admin,
    'OPERADOR' => RolUsuario.operador,
    _ => throw FormatException('rol desconocido recibido del backend: $value'),
  };
}

/// Entidad de dominio. Nunca carga `passwordHash`: el backend estructuralmente
/// no lo serializa, y este modelo tampoco tiene un campo para él.
class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nombre;
  final String email;
  final RolUsuario rol;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Usuario &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nombre == other.nombre &&
          email == other.email &&
          rol == other.rol &&
          activo == other.activo &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, nombre, email, rol, activo, createdAt, updatedAt);
}
