import { prisma } from '../../src/config/database.js';

const VALORES_POR_TIPO = {
  CARRO: { valorMinuto: 100, valorPlena: 20000, valorNocturna: 16000, valorMes: 180000 },
  MOTO: { valorMinuto: 60, valorPlena: 10000, valorNocturna: 8000, valorMes: 90000 },
  BICICLETA: { valorMinuto: 10, valorPlena: 2000, valorNocturna: 1600, valorMes: 40000 },
  OTRO: { valorMinuto: 0, valorPlena: 0, valorNocturna: 0, valorMes: 180000 },
};

export function buildTarifaPayload(overrides = {}) {
  const tipoVehiculo = overrides.tipoVehiculo ?? 'CARRO';
  return {
    tipoVehiculo,
    ...VALORES_POR_TIPO[tipoVehiculo],
    ...overrides,
  };
}

export async function createTarifaInDb(overrides = {}) {
  const tipoVehiculo = overrides.tipoVehiculo ?? 'CARRO';
  return prisma.tarifa.create({
    data: {
      tipoVehiculo,
      ...VALORES_POR_TIPO[tipoVehiculo],
      vigenteDesde: new Date('2020-01-01T00:00:00.000Z'),
      vigenteHasta: null,
      ...overrides,
    },
  });
}
