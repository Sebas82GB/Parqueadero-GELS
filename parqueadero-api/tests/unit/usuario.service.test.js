import { describe, it, expect, vi, beforeEach } from 'vitest';
import bcrypt from 'bcryptjs';
import { NotFoundError, ConflictError } from '../../src/errors/index.js';
import * as usuarioRepository from '../../src/repositories/usuario.repository.js';
import {
  listarUsuarios,
  obtenerUsuarioPorId,
  crearUsuario,
  actualizarUsuario,
} from '../../src/services/usuario.service.js';

vi.mock('../../src/repositories/usuario.repository.js', () => ({
  findMany: vi.fn(),
  findById: vi.fn(),
  findByEmail: vi.fn(),
  findAuthByEmail: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
}));

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

beforeEach(() => {
  vi.resetAllMocks();
});

describe('usuario.service', () => {
  describe('listarUsuarios', () => {
    it('devuelve usuarios sin filtros', async () => {
      const usuarios = [buildUsuario()];
      usuarioRepository.findMany.mockResolvedValue({ items: usuarios, total: 1 });

      const result = await listarUsuarios({ page: 1, perPage: 20 });

      expect(result).toEqual({ usuarios, total: 1, page: 1, perPage: 20 });
      expect(usuarioRepository.findMany).toHaveBeenCalledWith({
        rol: undefined,
        activo: undefined,
        page: 1,
        perPage: 20,
      });
    });

    it('pasa los filtros al repositorio', async () => {
      usuarioRepository.findMany.mockResolvedValue({ items: [], total: 0 });

      await listarUsuarios({ rol: 'OPERADOR', activo: true, page: 2, perPage: 10 });

      expect(usuarioRepository.findMany).toHaveBeenCalledWith({
        rol: 'OPERADOR',
        activo: true,
        page: 2,
        perPage: 10,
      });
    });
  });

  describe('obtenerUsuarioPorId', () => {
    it('devuelve el usuario si existe', async () => {
      const usuario = buildUsuario();
      usuarioRepository.findById.mockResolvedValue(usuario);

      const result = await obtenerUsuarioPorId(usuario.id);

      expect(result).toBe(usuario);
    });

    it('lanza NotFoundError si no existe', async () => {
      usuarioRepository.findById.mockResolvedValue(null);

      await expect(obtenerUsuarioPorId('inexistente')).rejects.toBeInstanceOf(NotFoundError);
    });
  });

  describe('crearUsuario', () => {
    it('crea el usuario hasheando la password con cost 12', async () => {
      usuarioRepository.findByEmail.mockResolvedValue(null);
      const usuario = buildUsuario();
      usuarioRepository.create.mockResolvedValue(usuario);

      const result = await crearUsuario({
        nombre: 'Ana Admin',
        email: 'ana@example.com',
        password: 'Password123!',
        rol: 'ADMIN',
      });

      expect(result).toBe(usuario);
      expect(usuarioRepository.create).toHaveBeenCalledTimes(1);

      const argumento = usuarioRepository.create.mock.calls[0][0];
      expect(argumento).toMatchObject({
        nombre: 'Ana Admin',
        email: 'ana@example.com',
        rol: 'ADMIN',
      });
      expect(argumento.passwordHash).not.toBe('Password123!');
      expect(argumento.passwordHash.startsWith('$2')).toBe(true);
      expect(bcrypt.compareSync('Password123!', argumento.passwordHash)).toBe(true);
    });

    it('lanza ConflictError si el email ya existe y no llama a create', async () => {
      usuarioRepository.findByEmail.mockResolvedValue(buildUsuario());

      await expect(
        crearUsuario({ nombre: 'Ana', email: 'ana@example.com', password: 'x', rol: 'ADMIN' }),
      ).rejects.toBeInstanceOf(ConflictError);
      expect(usuarioRepository.create).not.toHaveBeenCalled();
    });
  });

  describe('actualizarUsuario', () => {
    it('actualiza sin consultar findByEmail si el patch no trae email', async () => {
      const usuario = buildUsuario();
      usuarioRepository.findById.mockResolvedValue(usuario);
      usuarioRepository.update.mockResolvedValue({ ...usuario, nombre: 'Ana B' });

      const result = await actualizarUsuario(usuario.id, { nombre: 'Ana B' });

      expect(result.nombre).toBe('Ana B');
      expect(usuarioRepository.findByEmail).not.toHaveBeenCalled();
      expect(usuarioRepository.update).toHaveBeenCalledWith(usuario.id, { nombre: 'Ana B' });
    });

    it('rehashea la password si viene en el patch', async () => {
      const usuario = buildUsuario();
      usuarioRepository.findById.mockResolvedValue(usuario);
      usuarioRepository.update.mockResolvedValue(usuario);

      await actualizarUsuario(usuario.id, { password: 'NuevaPass123!' });

      const argumento = usuarioRepository.update.mock.calls[0][1];
      expect(argumento.password).toBeUndefined();
      expect(bcrypt.compareSync('NuevaPass123!', argumento.passwordHash)).toBe(true);
    });

    it('permite reenviar el mismo email sin conflicto', async () => {
      const usuario = buildUsuario();
      usuarioRepository.findById.mockResolvedValue(usuario);
      usuarioRepository.findByEmail.mockResolvedValue(usuario);
      usuarioRepository.update.mockResolvedValue(usuario);

      const result = await actualizarUsuario(usuario.id, { email: usuario.email });

      expect(result).toBe(usuario);
    });

    it('desactiva un usuario con activo: false', async () => {
      const usuario = buildUsuario({ activo: true });
      usuarioRepository.findById.mockResolvedValue(usuario);
      usuarioRepository.update.mockResolvedValue({ ...usuario, activo: false });

      const result = await actualizarUsuario(usuario.id, { activo: false });

      expect(result.activo).toBe(false);
      expect(usuarioRepository.update).toHaveBeenCalledWith(usuario.id, { activo: false });
    });

    it('lanza NotFoundError si el usuario no existe', async () => {
      usuarioRepository.findById.mockResolvedValue(null);

      await expect(actualizarUsuario('inexistente', { nombre: 'X' })).rejects.toBeInstanceOf(
        NotFoundError,
      );
    });

    it('lanza ConflictError si el email pertenece a otro usuario', async () => {
      const usuario = buildUsuario();
      const otro = buildUsuario({ id: 'otro-id', email: 'otro@example.com' });
      usuarioRepository.findById.mockResolvedValue(usuario);
      usuarioRepository.findByEmail.mockResolvedValue(otro);

      await expect(
        actualizarUsuario(usuario.id, { email: 'otro@example.com' }),
      ).rejects.toBeInstanceOf(ConflictError);
    });
  });
});
