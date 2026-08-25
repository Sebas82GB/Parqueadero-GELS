import { randomUUID } from 'node:crypto';
import { prisma } from '../../src/config/database.js';

function placaUnica() {
  return `T${randomUUID().slice(0, 6).toUpperCase()}`;
}

export function buildVehiculoPayload(overrides = {}) {
  return {
    placa: placaUnica(),
    tipoVehiculo: 'CARRO',
    ...overrides,
  };
}

export async function createVehiculoInDb(overrides = {}) {
  return prisma.vehiculo.create({
    data: {
      placa: placaUnica(),
      tipo: 'CARRO',
      ...overrides,
    },
  });
}
