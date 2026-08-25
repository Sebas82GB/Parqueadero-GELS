import { Prisma } from '@prisma/client';
import { prisma } from '../config/database.js';
import { Celda } from '../models/celda.js';
import { ConflictError } from '../errors/index.js';

function buildWhere({ zona, estado, tipoPermitido }) {
  return {
    ...(zona !== undefined && { zona: { equals: zona, mode: 'insensitive' } }),
    ...(estado !== undefined && { estado }),
    ...(tipoPermitido !== undefined && { tipoPermitido }),
  };
}

function traducirErrorCodigoDuplicado(err, codigo) {
  if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
    throw new ConflictError(
      `Ya existe una celda con el código "${codigo}"`,
      'CELDA_CODIGO_DUPLICADO',
    );
  }
  throw err;
}

export async function findMany({ zona, estado, tipoPermitido, page, perPage }) {
  const where = buildWhere({ zona, estado, tipoPermitido });

  const [records, total] = await Promise.all([
    prisma.celda.findMany({
      where,
      orderBy: { codigo: 'asc' },
      skip: (page - 1) * perPage,
      take: perPage,
    }),
    prisma.celda.count({ where }),
  ]);

  return { items: records.map(Celda.toDomain), total };
}

export async function findById(id) {
  const record = await prisma.celda.findUnique({ where: { id } });
  return record ? Celda.toDomain(record) : null;
}

export async function findByCodigo(codigo) {
  const record = await prisma.celda.findUnique({ where: { codigo } });
  return record ? Celda.toDomain(record) : null;
}

export async function create(data) {
  try {
    const record = await prisma.celda.create({ data: Celda.toPersistence(data) });
    return Celda.toDomain(record);
  } catch (err) {
    traducirErrorCodigoDuplicado(err, data.codigo);
  }
}

export async function update(id, data) {
  try {
    const record = await prisma.celda.update({ where: { id }, data: Celda.toPersistence(data) });
    return Celda.toDomain(record);
  } catch (err) {
    traducirErrorCodigoDuplicado(err, data.codigo);
  }
}
