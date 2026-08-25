import bcrypt from 'bcryptjs';
import { randomUUID } from 'node:crypto';
import { prisma } from '../../src/config/database.js';

const PASSWORD_PLANA = 'Password123!';

function emailUnico() {
  return `usuario-${randomUUID().slice(0, 8)}@example.com`;
}

export function buildUsuarioPayload(overrides = {}) {
  return {
    nombre: 'Usuario Test',
    email: emailUnico(),
    password: PASSWORD_PLANA,
    rol: 'OPERADOR',
    ...overrides,
  };
}

// Inserta directo con Prisma (sin pasar por la API) y devuelve también la
// password en texto plano, porque los tests de auth la necesitan para
// loguearse con el usuario recién creado.
export async function createUsuarioInDb(overrides = {}) {
  const { password = PASSWORD_PLANA, ...resto } = overrides;
  const passwordHash = await bcrypt.hash(password, 12);

  const usuario = await prisma.usuario.create({
    data: {
      nombre: 'Usuario Test',
      email: emailUnico(),
      rol: 'OPERADOR',
      activo: true,
      ...resto,
      passwordHash,
    },
  });

  return { usuario, password };
}
