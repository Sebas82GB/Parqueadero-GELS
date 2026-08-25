export class Tarifa {
  constructor({
    id,
    tipoVehiculo,
    valorMinuto,
    valorPlena,
    valorNocturna,
    valorMes,
    vigenteDesde,
    vigenteHasta,
    createdAt,
    updatedAt,
  }) {
    this.id = id;
    this.tipoVehiculo = tipoVehiculo;
    this.valorMinuto = valorMinuto;
    this.valorPlena = valorPlena;
    this.valorNocturna = valorNocturna;
    this.valorMes = valorMes;
    this.vigenteDesde = vigenteDesde;
    this.vigenteHasta = vigenteHasta;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  static toDomain(record) {
    return new Tarifa({
      id: record.id,
      tipoVehiculo: record.tipoVehiculo,
      valorMinuto: record.valorMinuto,
      valorPlena: record.valorPlena,
      valorNocturna: record.valorNocturna,
      valorMes: record.valorMes,
      vigenteDesde: record.vigenteDesde,
      vigenteHasta: record.vigenteHasta,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }

  static toPersistence({
    tipoVehiculo,
    valorMinuto,
    valorPlena,
    valorNocturna,
    valorMes,
    vigenteDesde,
    vigenteHasta,
  } = {}) {
    const data = {};
    if (tipoVehiculo !== undefined) data.tipoVehiculo = tipoVehiculo;
    if (valorMinuto !== undefined) data.valorMinuto = valorMinuto;
    if (valorPlena !== undefined) data.valorPlena = valorPlena;
    if (valorNocturna !== undefined) data.valorNocturna = valorNocturna;
    if (valorMes !== undefined) data.valorMes = valorMes;
    if (vigenteDesde !== undefined) data.vigenteDesde = vigenteDesde;
    if (vigenteHasta !== undefined) data.vigenteHasta = vigenteHasta;
    return data;
  }
}
