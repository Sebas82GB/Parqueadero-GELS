import { Prisma } from '@prisma/client';
import { prisma } from '../config/database.js';
import { Usuario } from '../models/usuario.js';
import { ConflictError } from '../errors/index.js';

function buildWhere({ rol, activo }) {
  return {
    ...(rol !== undefined && { rol }),
    ...(activo !== undefined && { activo }),
  };
}

function traducirErrorEmailDuplicado(err, email) {
  if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
    throw new ConflictError(`Ya existe un usuario con el email "${email}"`, 'EMAIL_DUPLICADO');
  }
  throw err;
}

export async function findMany({ rol, activo, page, perPage }) {
  const where = buildWhere({ rol, activo });

  const [records, total] = await Promise.all([
    prisma.usuario.findMany({
      where,
      orderBy: { nombre: 'asc' },
      skip: (page - 1) * perPage,
      take: perPage,
    }),
    prisma.usuario.count({ where }),
  ]);

  return { items: records.map(Usuario.toDomain), total };
}

export async function findById(id) {
  const record = await prisma.usuario.findUnique({ where: { id } });
  return record ? Usuario.toDomain(record) : null;
}

export async function findByEmail(email) {
  const record = await prisma.usuario.findUnique({ where: { email } });
  return record ? Usuario.toDomain(record) : null;
}

// Único método que devuelve el hash: no construye un Usuario de dominio a
// propósito, para que no pueda terminar serializado en una respuesta. Solo
// lo debe llamar auth.service para verificar credenciales de login.
export async function findAuthByEmail(email) {
  const record = await prisma.usuario.findUnique({
    where: { email },
    select: { id: true, passwordHash: true, rol: true, activo: true },
  });
  return record ?? null;
}

export async function create(data) {
  try {
    const record = await prisma.usuario.create({ data: Usuario.toPersistence(data) });
    return Usuario.toDomain(record);
  } catch (err) {
    traducirErrorEmailDuplicado(err, data.email);
  }
}

export async function update(id, data) {
  try {
    const record = await prisma.usuario.update({
      where: { id },
      data: Usuario.toPersistence(data),
    });
    return Usuario.toDomain(record);
  } catch (err) {
    traducirErrorEmailDuplicado(err, data.email);
  }
}
