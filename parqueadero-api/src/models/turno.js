export class Turno {
  constructor({
    id,
    operadorId,
    apertura,
    cierre,
    baseInicial,
    totalRecaudado,
    efectivoContado,
    efectivoEsperado,
    diferencia,
    estado,
    validadoPorId,
    validadoEn,
    createdAt,
    updatedAt,
  }) {
    this.id = id;
    this.operadorId = operadorId;
    this.apertura = apertura;
    this.cierre = cierre;
    this.baseInicial = baseInicial;
    this.totalRecaudado = totalRecaudado;
    this.efectivoContado = efectivoContado;
    this.efectivoEsperado = efectivoEsperado;
    this.diferencia = diferencia;
    this.estado = estado;
    this.validadoPorId = validadoPorId;
    this.validadoEn = validadoEn;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  static toDomain(record) {
    return new Turno({
      id: record.id,
      operadorId: record.operadorId,
      apertura: record.apertura,
      cierre: record.cierre,
      baseInicial: record.baseInicial,
      totalRecaudado: record.totalRecaudado,
      efectivoContado: record.efectivoContado,
      efectivoEsperado: record.efectivoEsperado,
      diferencia: record.diferencia,
      estado: record.estado,
      validadoPorId: record.validadoPorId,
      validadoEn: record.validadoEn,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }

  static toPersistence({
    operadorId,
    baseInicial,
    cierre,
    totalRecaudado,
    efectivoContado,
    efectivoEsperado,
    diferencia,
    estado,
    validadoPorId,
    validadoEn,
  } = {}) {
    const data = {};
    if (operadorId !== undefined) data.operadorId = operadorId;
    if (baseInicial !== undefined) data.baseInicial = baseInicial;
    if (cierre !== undefined) data.cierre = cierre;
    if (totalRecaudado !== undefined) data.totalRecaudado = totalRecaudado;
    if (efectivoContado !== undefined) data.efectivoContado = efectivoContado;
    if (efectivoEsperado !== undefined) data.efectivoEsperado = efectivoEsperado;
    if (diferencia !== undefined) data.diferencia = diferencia;
    if (estado !== undefined) data.estado = estado;
    if (validadoPorId !== undefined) data.validadoPorId = validadoPorId;
    if (validadoEn !== undefined) data.validadoEn = validadoEn;
    return data;
  }
}
