import { prisma } from '../config/database.js';
import { RefreshToken } from '../models/refresh-token.js';

export async function create(data) {
  const record = await prisma.refreshToken.create({ data: RefreshToken.toPersistence(data) });
  return RefreshToken.toDomain(record);
}

// Devuelve el registro tal cual exista (revocado, expirado o no); decidir
// si sigue siendo válido es responsabilidad del servicio, no del repositorio.
export async function findByHash(tokenHash) {
  const record = await prisma.refreshToken.findUnique({ where: { tokenHash } });
  return record ? RefreshToken.toDomain(record) : null;
}

export async function revoke(id) {
  const record = await prisma.refreshToken.update({
    where: { id },
    data: { revokedAt: new Date() },
  });
  return RefreshToken.toDomain(record);
}
