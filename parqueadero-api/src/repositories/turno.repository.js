import { prisma } from '../config/database.js';
import { Turno } from '../models/turno.js';
import { ConflictError } from '../errors/index.js';

export async function findById(id) {
  const record = await prisma.turno.findUnique({ where: { id } });
  return record ? Turno.toDomain(record) : null;
}

export async function findAbiertoByOperador(operadorId) {
  const record = await prisma.turno.findFirst({
    where: { operadorId, estado: 'ABIERTO' },
    orderBy: { apertura: 'desc' },
  });
  return record ? Turno.toDomain(record) : null;
}

export async function create({ operadorId, baseInicial }) {
  const record = await prisma.turno.create({
    data: Turno.toPersistence({ operadorId, baseInicial }),
  });
  return Turno.toDomain(record);
}

// Guardia de concurrencia: solo cierra si sigue ABIERTO. Si otra petición ya
// lo cerró entre el findById del servicio y este update, count queda en 0.
export async function cerrar(
  id,
  { cierre, totalRecaudado, efectivoContado, efectivoEsperado, diferencia },
) {
  const { count } = await prisma.turno.updateMany({
    where: { id, estado: 'ABIERTO' },
    data: Turno.toPersistence({
      cierre,
      totalRecaudado,
      efectivoContado,
      efectivoEsperado,
      diferencia,
      estado: 'CERRADO',
    }),
  });

  if (count === 0) {
    throw new ConflictError('El turno ya está cerrado', 'TURNO_YA_CERRADO');
  }

  return findById(id);
}

function buildWhere({ operadorId, estado, desde, hasta }) {
  return {
    ...(operadorId !== undefined && { operadorId }),
    ...(estado !== undefined && { estado }),
    ...((desde !== undefined || hasta !== undefined) && {
      apertura: {
        ...(desde !== undefined && { gte: desde }),
        ...(hasta !== undefined && { lte: hasta }),
      },
    }),
  };
}

export async function findMany({ operadorId, estado, desde, hasta, page, perPage }) {
  const where = buildWhere({ operadorId, estado, desde, hasta });

  const [records, total] = await Promise.all([
    prisma.turno.findMany({
      where,
      orderBy: { apertura: 'desc' },
      skip: (page - 1) * perPage,
      take: perPage,
    }),
    prisma.turno.count({ where }),
  ]);

  return { items: records.map(Turno.toDomain), total };
}
