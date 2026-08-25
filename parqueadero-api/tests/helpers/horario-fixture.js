import { prisma } from '../../src/config/database.js';

const VALORES_POR_DEFECTO = { apertura: '08:00', cierre: '21:30' };

export function buildHorarioPayload(overrides = {}) {
  return { ...VALORES_POR_DEFECTO, ...overrides };
}

export async function createHorarioInDb(overrides = {}) {
  const { apertura, cierre, ...resto } = { ...VALORES_POR_DEFECTO, ...overrides };
  return prisma.horarioOperacion.create({
    data: {
      apertura: new Date(`1970-01-01T${apertura}:00Z`),
      cierre: new Date(`1970-01-01T${cierre}:00Z`),
      vigenteDesde: new Date('2020-01-01T00:00:00.000Z'),
      vigenteHasta: null,
      ...resto,
    },
  });
}
