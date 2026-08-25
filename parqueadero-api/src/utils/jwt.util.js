import jwt from 'jsonwebtoken';
import { createHash, randomUUID } from 'node:crypto';
import { env } from '../config/env.js';

export function generateAccessToken(usuario) {
  return jwt.sign({ sub: usuario.id, rol: usuario.rol }, env.JWT_ACCESS_SECRET, {
    expiresIn: env.JWT_ACCESS_EXPIRES_IN,
  });
}

export function generateRefreshToken(usuario) {
  // jti evita que dos tokens firmados en el mismo segundo para el mismo
  // usuario (ej. dos logins casi simultáneos) sean bit-a-bit idénticos: la
  // firma HMAC es determinística, y tokenHash es @unique en la BD.
  return jwt.sign({ sub: usuario.id, jti: randomUUID() }, env.JWT_REFRESH_SECRET, {
    expiresIn: env.JWT_REFRESH_EXPIRES_IN,
  });
}

// Lanza si el token es inválido o expiró; el caller no necesita distinguir
// el motivo, solo traducirlo a un 401 uniforme.
export function verifyRefreshToken(token) {
  return jwt.verify(token, env.JWT_REFRESH_SECRET);
}

// Clave de búsqueda determinística para persistir el refresh token: nunca
// se guarda el JWT en texto plano (equivaldría a guardar una credencial
// viva), y bcrypt no sirve aquí porque no permite un lookup por igualdad.
export function hashToken(token) {
  return createHash('sha256').update(token).digest('hex');
}
