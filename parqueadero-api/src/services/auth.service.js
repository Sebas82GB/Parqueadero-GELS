import bcrypt from 'bcryptjs';
import * as usuarioRepository from '../repositories/usuario.repository.js';
import * as refreshTokenRepository from '../repositories/refresh-token.repository.js';
import { obtenerUsuarioPorId } from './usuario.service.js';
import { UnauthorizedError } from '../errors/index.js';
import {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
  hashToken,
} from '../utils/jwt.util.js';

const BCRYPT_COST = 12;
// Hash fijo contra el que se compara cuando el email no existe, para que
// bcrypt.compare tarde lo mismo que con un usuario real y el tiempo de
// respuesta no delate si el email existe o no.
const DUMMY_HASH = bcrypt.hashSync('credenciales-invalidas', BCRYPT_COST);

function credencialesInvalidas() {
  return new UnauthorizedError('Credenciales inválidas', 'CREDENCIALES_INVALIDAS');
}

function refreshTokenInvalido() {
  return new UnauthorizedError('Refresh token inválido o expirado', 'REFRESH_TOKEN_INVALIDO');
}

function verificarRefreshTokenOLanzar(token) {
  try {
    return verifyRefreshToken(token);
  } catch {
    throw refreshTokenInvalido();
  }
}

async function emitirTokens(usuario) {
  const accessToken = generateAccessToken(usuario);
  const refreshToken = generateRefreshToken(usuario);
  const { exp } = verifyRefreshToken(refreshToken);

  await refreshTokenRepository.create({
    usuarioId: usuario.id,
    tokenHash: hashToken(refreshToken),
    expiresAt: new Date(exp * 1000),
  });

  return { accessToken, refreshToken };
}

export async function login({ email, password }) {
  const credenciales = await usuarioRepository.findAuthByEmail(email);
  const passwordCorrecta = await bcrypt.compare(password, credenciales?.passwordHash ?? DUMMY_HASH);

  if (!credenciales || !credenciales.activo || !passwordCorrecta) {
    throw credencialesInvalidas();
  }

  const usuario = await usuarioRepository.findById(credenciales.id);
  const tokens = await emitirTokens(usuario);
  return { usuario, ...tokens };
}

export async function refresh(refreshToken) {
  const payload = verificarRefreshTokenOLanzar(refreshToken);
  const registro = await refreshTokenRepository.findByHash(hashToken(refreshToken));

  if (!registro || registro.revokedAt || registro.expiresAt < new Date()) {
    throw refreshTokenInvalido();
  }

  // Se re-lee el usuario en vez de confiar en el payload: si un ADMIN lo
  // desactivó después del login, el refresh debe cortar la sesión igual.
  const usuario = await usuarioRepository.findById(payload.sub);
  if (!usuario || !usuario.activo) {
    throw refreshTokenInvalido();
  }

  await refreshTokenRepository.revoke(registro.id);
  return emitirTokens(usuario);
}

export async function logout(refreshToken) {
  verificarRefreshTokenOLanzar(refreshToken);
  const registro = await refreshTokenRepository.findByHash(hashToken(refreshToken));

  // Idempotente: si ya no existe o ya estaba revocado, el estado deseado
  // ("este token ya no sirve") igual se cumple.
  if (registro && !registro.revokedAt) {
    await refreshTokenRepository.revoke(registro.id);
  }
}

export async function me(usuarioId) {
  return obtenerUsuarioPorId(usuarioId);
}
