export class Celda {
  constructor({ id, codigo, zona, tipoPermitido, estado, createdAt, updatedAt }) {
    this.id = id;
    this.codigo = codigo;
    this.zona = zona;
    this.tipoPermitido = tipoPermitido;
    this.estado = estado;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  static toDomain(record) {
    return new Celda({
      id: record.id,
      codigo: record.codigo,
      zona: record.zona,
      tipoPermitido: record.tipoPermitido,
      estado: record.estado,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }

  static toPersistence({ codigo, zona, tipoPermitido, estado } = {}) {
    const data = {};
    if (codigo !== undefined) data.codigo = codigo;
    if (zona !== undefined) data.zona = zona;
    if (tipoPermitido !== undefined) data.tipoPermitido = tipoPermitido;
    if (estado !== undefined) data.estado = estado;
    return data;
  }
}
