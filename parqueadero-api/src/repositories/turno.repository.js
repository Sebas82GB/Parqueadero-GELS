import { prisma } from '../config/database.js';
import { Turno } from '../models/turno.js';
import { ConflictError } from '../errors/index.js';
import { toSkipTake } from '../utils/paginacion.util.js';

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

// Transición automática (turno.service.js#resolverTurnoAutomatico), disparada
// de forma perezosa al consultar el turno, no por un scheduler. Se ignora
// silenciosamente si count da 0: significa que otra petición concurrente ya
// lo resolvió primero, no es un conflicto que el llamador necesite ver.
export async function marcarPendienteArqueo(id, { cierre, totalRecaudado, efectivoEsperado }) {
  const { count } = await prisma.turno.updateMany({
    where: { id, estado: 'ABIERTO' },
    data: Turno.toPersistence({
      cierre,
      totalRecaudado,
      efectivoEsperado,
      estado: 'CERRADO_PENDIENTE_ARQUEO',
    }),
  });

  if (count === 0) return null;
  return findById(id);
}

// Guardia de concurrencia igual que cerrar(): solo completa el arqueo si
// seguía CERRADO_PENDIENTE_ARQUEO. Aquí sí se lanza el error de dominio (a
// diferencia de marcarPendienteArqueo) porque esta transición la pide un
// ADMIN explícitamente, no es un efecto perezoso de fondo.
export async function completarArqueo(id, { efectivoContado, diferencia, validadoPorId, validadoEn }) {
  const { count } = await prisma.turno.updateMany({
    where: { id, estado: 'CERRADO_PENDIENTE_ARQUEO' },
    data: Turno.toPersistence({
      efectivoContado,
      diferencia,
      validadoPorId,
      validadoEn,
      estado: 'CERRADO',
    }),
  });

  if (count === 0) {
    throw new ConflictError('El turno no está pendiente de arqueo', 'TURNO_NO_PENDIENTE_ARQUEO');
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
      ...toSkipTake(page, perPage),
    }),
    prisma.turno.count({ where }),
  ]);

  return { items: records.map(Turno.toDomain), total };
}
