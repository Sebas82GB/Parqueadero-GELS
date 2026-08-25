// apertura/cierre se guardan en Postgres como TIME (sin fecha ni zona): son
// hora local pura. El dominio los expone como strings "HH:mm"; estas dos
// funciones son el único punto de conversión Date↔string, igual que
// toDomain/toPersistence son el único punto de conversión Prisma↔dominio.
function toHoraString(date) {
  const horas = String(date.getUTCHours()).padStart(2, '0');
  const minutos = String(date.getUTCMinutes()).padStart(2, '0');
  return `${horas}:${minutos}`;
}

function toHoraDate(hhmm) {
  const [horas, minutos] = hhmm.split(':').map(Number);
  return new Date(Date.UTC(1970, 0, 1, horas, minutos, 0));
}

export class HorarioOperacion {
  constructor({ id, apertura, cierre, vigenteDesde, vigenteHasta, createdAt, updatedAt }) {
    this.id = id;
    this.apertura = apertura;
    this.cierre = cierre;
    this.vigenteDesde = vigenteDesde;
    this.vigenteHasta = vigenteHasta;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  static toDomain(record) {
    return new HorarioOperacion({
      id: record.id,
      apertura: toHoraString(record.apertura),
      cierre: toHoraString(record.cierre),
      vigenteDesde: record.vigenteDesde,
      vigenteHasta: record.vigenteHasta,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }

  static toPersistence({ apertura, cierre, vigenteDesde, vigenteHasta } = {}) {
    const data = {};
    if (apertura !== undefined) data.apertura = toHoraDate(apertura);
    if (cierre !== undefined) data.cierre = toHoraDate(cierre);
    if (vigenteDesde !== undefined) data.vigenteDesde = vigenteDesde;
    if (vigenteHasta !== undefined) data.vigenteHasta = vigenteHasta;
    return data;
  }
}
