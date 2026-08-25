export class Vehiculo {
  constructor({ id, placa, tipo, propietarioNombre, propietarioTelefono, createdAt, updatedAt }) {
    this.id = id;
    this.placa = placa;
    this.tipo = tipo;
    this.propietarioNombre = propietarioNombre;
    this.propietarioTelefono = propietarioTelefono;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  static toDomain(record) {
    return new Vehiculo({
      id: record.id,
      placa: record.placa,
      tipo: record.tipo,
      propietarioNombre: record.propietarioNombre,
      propietarioTelefono: record.propietarioTelefono,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }

  static toPersistence({ placa, tipo, propietarioNombre, propietarioTelefono } = {}) {
    const data = {};
    if (placa !== undefined) data.placa = placa;
    if (tipo !== undefined) data.tipo = tipo;
    if (propietarioNombre !== undefined) data.propietarioNombre = propietarioNombre;
    if (propietarioTelefono !== undefined) data.propietarioTelefono = propietarioTelefono;
    return data;
  }
}
