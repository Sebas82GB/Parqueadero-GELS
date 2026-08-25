import { describe, it, expect, vi, beforeEach } from 'vitest';
import bcrypt from 'bcryptjs';
import { UnauthorizedError, NotFoundError } from '../../src/errors/index.js';
import * as usuarioRepository from '../../src/repositories/usuario.repository.js';
import * as refreshTokenRepository from '../../src/repositories/refresh-token.repository.js';
import { generateRefreshToken } from '../../src/utils/jwt.util.js';
import { login, refresh, logout, me } from '../../src/services/auth.service.js';

vi.mock('../../src/repositories/usuario.repository.js', () => ({
  findMany: vi.fn(),
  findById: vi.fn(),
  findByEmail: vi.fn(),
  findAuthByEmail: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
}));

vi.mock('../../src/repositories/refresh-token.repository.js', () => ({
  create: vi.fn(),
  findByHash: vi.fn(),
  revoke: vi.fn(),
}));

const PASSWORD_VALIDA = 'Password123!';
// Se calcula una sola vez al cargar el módulo (cost 12 es lento a propósito).
const passwordHash = await bcrypt.hash(PASSWORD_VALIDA, 12);

function buildUsuario(overrides = {}) {
  return {
    id: 'usuario-id-1',
    nombre: 'Ana Admin',
    email: 'ana@example.com',
    rol: 'ADMIN',
    activo: true,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

function buildCredenciales(overrides = {}) {
  return {
    id: 'usuario-id-1',
    passwordHash,
    rol: 'ADMIN',
    activo: true,
    ...overrides,
  };
}

function buildRegistroToken(overrides = {}) {
  return {
    id: 'refresh-token-id-1',
    usuarioId: 'usuario-id-1',
    tokenHash: 'hash-no-relevante-porque-el-repo-esta-mockeado',
    expiresAt: new Date(Date.now() + 60_000),
    revokedAt: null,
    createdAt: new Date(),
    ...overrides,
  };
}

beforeEach(() => {
  vi.resetAllMocks();
});

describe('auth.service', () => {
  describe('login', () => {
    it('inicia sesión y persiste el refresh token emitido', async () => {
      const usuario = buildUsuario();
      usuarioRepository.findAuthByEmail.mockResolvedValue(buildCredenciales());
      usuarioRepository.findById.mockResolvedValue(usuario);
      refreshTokenRepository.create.mockResolvedValue(buildRegistroToken());

      const result = await login({ email: usuario.email, password: PASSWORD_VALIDA });

      expect(result.usuario).toBe(usuario);
      expect(typeof result.accessToken).toBe('string');
      expect(typeof result.refreshToken).toBe('string');
      expect(refreshTokenRepository.create).toHaveBeenCalledTimes(1);
      expect(refreshTokenRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({ usuarioId: usuario.id }),
      );
    });

    it('lanza el mismo 401 CREDENCIALES_INVALIDAS con email inexistente, password incorrecta o usuario inactivo', async () => {
      usuarioRepository.findAuthByEmail.mockResolvedValueOnce(null);
      const errorEmailInexistente = await login({
        email: 'no-existe@example.com',
        password: PASSWORD_VALIDA,
      }).catch((e) => e);

      usuarioRepository.findAuthByEmail.mockResolvedValueOnce(buildCredenciales());
      const errorPasswordIncorrecta = await login({
        email: 'ana@example.com',
        password: 'otra-password',
      }).catch((e) => e);

      usuarioRepository.findAuthByEmail.mockResolvedValueOnce(buildCredenciales({ activo: false }));
      const errorInactivo = await login({
        email: 'ana@example.com',
        password: PASSWORD_VALIDA,
      }).catch((e) => e);

      for (const error of [errorEmailInexistente, errorPasswordIncorrecta, errorInactivo]) {
        expect(error).toBeInstanceOf(UnauthorizedError);
        expect(error.code).toBe('CREDENCIALES_INVALIDAS');
        expect(error.message).toBe(errorEmailInexistente.message);
      }
      expect(usuarioRepository.findById).not.toHaveBeenCalled();
      expect(refreshTokenRepository.create).not.toHaveBeenCalled();
    });
  });

  describe('refresh', () => {
    it('rota el refresh token: revoca el viejo y emite un par nuevo', async () => {
      const usuario = buildUsuario();
      const token = generateRefreshToken(usuario);
      const registro = buildRegistroToken();

      refreshTokenRepository.findByHash.mockResolvedValue(registro);
      usuarioRepository.findById.mockResolvedValue(usuario);
      refreshTokenRepository.create.mockResolvedValue(buildRegistroToken());

      const result = await refresh(token);

      expect(typeof result.accessToken).toBe('string');
      expect(typeof result.refreshToken).toBe('string');
      expect(refreshTokenRepository.revoke).toHaveBeenCalledWith(registro.id);
      expect(refreshTokenRepository.create).toHaveBeenCalledTimes(1);
    });

    it('lanza 401 REFRESH_TOKEN_INVALIDO con un token que no es un JWT válido', async () => {
      const error = await refresh('esto-no-es-un-jwt').catch((e) => e);

      expect(error).toBeInstanceOf(UnauthorizedError);
      expect(error.code).toBe('REFRESH_TOKEN_INVALIDO');
      expect(refreshTokenRepository.findByHash).not.toHaveBeenCalled();
    });

    it('lanza 401 si el token no está persistido', async () => {
      const token = generateRefreshToken(buildUsuario());
      refreshTokenRepository.findByHash.mockResolvedValue(null);

      const error = await refresh(token).catch((e) => e);

      expect(error).toBeInstanceOf(UnauthorizedError);
      expect(error.code).toBe('REFRESH_TOKEN_INVALIDO');
    });

    it('lanza 401 si el token ya estaba revocado', async () => {
      const token = generateRefreshToken(buildUsuario());
      refreshTokenRepository.findByHash.mockResolvedValue(
        buildRegistroToken({ revokedAt: new Date() }),
      );

      const error = await refresh(token).catch((e) => e);

      expect(error).toBeInstanceOf(UnauthorizedError);
      expect(error.code).toBe('REFRESH_TOKEN_INVALIDO');
    });

    it('lanza 401 si el registro persistido ya expiró', async () => {
      const token = generateRefreshToken(buildUsuario());
      refreshTokenRepository.findByHash.mockResolvedValue(
        buildRegistroToken({ expiresAt: new Date(Date.now() - 1000) }),
      );

      const error = await refresh(token).catch((e) => e);

      expect(error).toBeInstanceOf(UnauthorizedError);
      expect(error.code).toBe('REFRESH_TOKEN_INVALIDO');
    });

    it('lanza 401 si el usuario fue desactivado después de emitir el token', async () => {
      const usuario = buildUsuario({ activo: false });
      const token = generateRefreshToken(usuario);
      refreshTokenRepository.findByHash.mockResolvedValue(buildRegistroToken());
      usuarioRepository.findById.mockResolvedValue(usuario);

      const error = await refresh(token).catch((e) => e);

      expect(error).toBeInstanceOf(UnauthorizedError);
      expect(error.code).toBe('REFRESH_TOKEN_INVALIDO');
      expect(refreshTokenRepository.revoke).not.toHaveBeenCalled();
    });
  });

  describe('logout', () => {
    it('revoca el refresh token si existe y no estaba revocado', async () => {
      const token = generateRefreshToken(buildUsuario());
      const registro = buildRegistroToken();
      refreshTokenRepository.findByHash.mockResolvedValue(registro);

      await logout(token);

      expect(refreshTokenRepository.revoke).toHaveBeenCalledWith(registro.id);
    });

    it('es idempotente si el token ya estaba revocado', async () => {
      const token = generateRefreshToken(buildUsuario());
      refreshTokenRepository.findByHash.mockResolvedValue(
        buildRegistroToken({ revokedAt: new Date() }),
      );

      await expect(logout(token)).resolves.toBeUndefined();
      expect(refreshTokenRepository.revoke).not.toHaveBeenCalled();
    });

    it('es idempotente si el token no está persistido', async () => {
      const token = generateRefreshToken(buildUsuario());
      refreshTokenRepository.findByHash.mockResolvedValue(null);

      await expect(logout(token)).resolves.toBeUndefined();
      expect(refreshTokenRepository.revoke).not.toHaveBeenCalled();
    });

    it('lanza 401 con un token que no es un JWT válido', async () => {
      const error = await logout('esto-no-es-un-jwt').catch((e) => e);

      expect(error).toBeInstanceOf(UnauthorizedError);
      expect(error.code).toBe('REFRESH_TOKEN_INVALIDO');
    });
  });

  describe('me', () => {
    it('devuelve el usuario autenticado', async () => {
      const usuario = buildUsuario();
      usuarioRepository.findById.mockResolvedValue(usuario);

      const result = await me(usuario.id);

      expect(result).toBe(usuario);
    });

    it('lanza NotFoundError si el usuario ya no existe', async () => {
      usuarioRepository.findById.mockResolvedValue(null);

      await expect(me('inexistente')).rejects.toBeInstanceOf(NotFoundError);
    });
  });
});
