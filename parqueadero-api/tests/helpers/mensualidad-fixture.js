import { randomUUID } from 'node:crypto';
import { prisma } from '../../src/config/database.js';

function placaUnica() {
  return `M${randomUUID().slice(0, 6).toUpperCase()}`;
}

// Para bodies HTTP de POST /mensualidades: trae placa+tipoVehiculo (el
// endpoint crea o reutiliza el vehículo), no vehiculoId.
export function buildMensualidadPayload(overrides = {}) {
  return {
    placa: placaUnica(),
    tipoVehiculo: 'CARRO',
    fechaInicio: new Date('2020-01-01T00:00:00.000Z').toISOString(),
    fechaFin: new Date('2099-01-01T00:00:00.000Z').toISOString(),
    valorMensualidad: 180000,
    ...overrides,
  };
}

export async function createMensualidadInDb(overrides = {}) {
  return prisma.mensualidad.create({
    data: {
      fechaInicio: new Date('2020-01-01T00:00:00.000Z'),
      fechaFin: new Date('2099-01-01T00:00:00.000Z'),
      valorMensualidad: 180000,
      estadoPago: 'PAGADA',
      ...overrides,
    },
  });
}
