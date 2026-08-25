import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { UnauthorizedError } from '../errors/index.js';

const BEARER_PATTERN = /^Bearer\s+(\S+)$/;

export function auth(req, res, next) {
  const header = req.headers.authorization;

  if (!header) {
    throw new UnauthorizedError('No se proporcionó un token de autenticación');
  }

  const match = header.match(BEARER_PATTERN);
  if (!match) {
    throw new UnauthorizedError('Formato de token inválido, se espera "Bearer <token>"');
  }

  try {
    const payload = jwt.verify(match[1], env.JWT_ACCESS_SECRET);
    req.user = { id: payload.sub, rol: payload.rol };
  } catch {
    throw new UnauthorizedError('Token inválido o expirado');
  }

  next();
}
