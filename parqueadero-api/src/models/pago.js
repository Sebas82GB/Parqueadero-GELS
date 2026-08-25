export class Pago {
  constructor({
    id,
    ticketId,
    mensualidadId,
    monto,
    metodo,
    turnoId,
    fecha,
    estado,
    createdAt,
    updatedAt,
  }) {
    this.id = id;
    this.ticketId = ticketId;
    this.mensualidadId = mensualidadId;
    this.monto = monto;
    this.metodo = metodo;
    this.turnoId = turnoId;
    this.fecha = fecha;
    this.estado = estado;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  static toDomain(record) {
    return new Pago({
      id: record.id,
      ticketId: record.ticketId,
      mensualidadId: record.mensualidadId,
      monto: record.monto,
      metodo: record.metodo,
      turnoId: record.turnoId,
      fecha: record.fecha,
      estado: record.estado,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }
}
