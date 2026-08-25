import { randomUUID } from 'node:crypto';
import { prisma } from '../../src/config/database.js';

function codigoUnico() {
  return `T-${randomUUID().slice(0, 8).toUpperCase()}`;
}

export function buildCeldaPayload(overrides = {}) {
  return {
    codigo: codigoUnico(),
    zona: 'Zona Test',
    tipoPermitido: 'CARRO',
    ...overrides,
  };
}

export async function createCeldaInDb(overrides = {}) {
  return prisma.celda.create({
    data: {
      codigo: codigoUnico(),
      zona: 'Zona Test',
      tipoPermitido: 'CARRO',
      estado: 'LIBRE',
      ...overrides,
    },
  });
}
