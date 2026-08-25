export class Usuario {
  constructor({ id, nombre, email, rol, activo, createdAt, updatedAt }) {
    this.id = id;
    this.nombre = nombre;
    this.email = email;
    this.rol = rol;
    this.activo = activo;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  // A propósito no lee record.passwordHash: la entidad de dominio no puede
  // filtrar el hash aunque un controlador la serialice directo en res.json.
  static toDomain(record) {
    return new Usuario({
      id: record.id,
      nombre: record.nombre,
      email: record.email,
      rol: record.rol,
      activo: record.activo,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }

  static toPersistence({ nombre, email, passwordHash, rol, activo } = {}) {
    const data = {};
    if (nombre !== undefined) data.nombre = nombre;
    if (email !== undefined) data.email = email;
    if (passwordHash !== undefined) data.passwordHash = passwordHash;
    if (rol !== undefined) data.rol = rol;
    if (activo !== undefined) data.activo = activo;
    return data;
  }
}
