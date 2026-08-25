import { prisma } from '../../src/config/database.js';

export async function createTurnoInDb(overrides = {}) {
  return prisma.turno.create({
    data: {
      baseInicial: 50000,
      estado: 'ABIERTO',
      ...overrides,
    },
  });
}
