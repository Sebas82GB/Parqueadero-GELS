export class Mensualidad {
  constructor({
    id,
    vehiculoId,
    celdaId,
    fechaInicio,
    fechaFin,
    valorMensualidad,
    estadoPago,
    fechaPago,
    createdAt,
    updatedAt,
  }) {
    this.id = id;
    this.vehiculoId = vehiculoId;
    this.celdaId = celdaId;
    this.fechaInicio = fechaInicio;
    this.fechaFin = fechaFin;
    this.valorMensualidad = valorMensualidad;
    this.estadoPago = estadoPago;
    this.fechaPago = fechaPago;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  static toDomain(record) {
    return new Mensualidad({
      id: record.id,
      vehiculoId: record.vehiculoId,
      celdaId: record.celdaId,
      fechaInicio: record.fechaInicio,
      fechaFin: record.fechaFin,
      valorMensualidad: record.valorMensualidad,
      estadoPago: record.estadoPago,
      fechaPago: record.fechaPago,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }

  static toPersistence({
    vehiculoId,
    celdaId,
    fechaInicio,
    fechaFin,
    valorMensualidad,
    estadoPago,
    fechaPago,
  } = {}) {
    const data = {};
    if (vehiculoId !== undefined) data.vehiculoId = vehiculoId;
    if (celdaId !== undefined) data.celdaId = celdaId;
    if (fechaInicio !== undefined) data.fechaInicio = fechaInicio;
    if (fechaFin !== undefined) data.fechaFin = fechaFin;
    if (valorMensualidad !== undefined) data.valorMensualidad = valorMensualidad;
    if (estadoPago !== undefined) data.estadoPago = estadoPago;
    if (fechaPago !== undefined) data.fechaPago = fechaPago;
    return data;
  }
}
