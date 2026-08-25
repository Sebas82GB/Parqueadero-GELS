import jwt from 'jsonwebtoken';
import { randomUUID } from 'node:crypto';
import { env } from '../../src/config/env.js';

export function signTestToken({
  id = randomUUID(),
  rol = 'ADMIN',
  expiresIn = env.JWT_ACCESS_EXPIRES_IN,
  secret = env.JWT_ACCESS_SECRET,
} = {}) {
  return jwt.sign({ sub: id, rol }, secret, { expiresIn });
}
