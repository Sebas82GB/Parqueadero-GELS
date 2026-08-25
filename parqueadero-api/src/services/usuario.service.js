import bcrypt from 'bcryptjs';
import * as usuarioRepository from '../repositories/usuario.repository.js';
import { NotFoundError, ConflictError } from '../errors/index.js';

const BCRYPT_COST = 12;

export async function listarUsuarios(query) {
  const { rol, activo, page, perPage } = query;
  const { items, total } = await usuarioRepository.findMany({ rol, activo, page, perPage });
  return { usuarios: items, total, page, perPage };
}

export async function obtenerUsuarioPorId(id) {
  const usuario = await usuarioRepository.findById(id);
  if (!usuario) {
    throw new NotFoundError(`Usuario con id "${id}" no encontrado`, 'USUARIO_NO_ENCONTRADO');
  }
  return usuario;
}

export async function crearUsuario({ nombre, email, password, rol }) {
  const existente = await usuarioRepository.findByEmail(email);
  if (existente) {
    throw new ConflictError(`Ya existe un usuario con el email "${email}"`, 'EMAIL_DUPLICADO');
  }

  const passwordHash = await bcrypt.hash(password, BCRYPT_COST);
  return usuarioRepository.create({ nombre, email, passwordHash, rol });
}

export async function actualizarUsuario(id, data) {
  const usuario = await obtenerUsuarioPorId(id);

  if (data.email !== undefined) {
    const existente = await usuarioRepository.findByEmail(data.email);
    if (existente && existente.id !== usuario.id) {
      throw new ConflictError(
        `Ya existe un usuario con el email "${data.email}"`,
        'EMAIL_DUPLICADO',
      );
    }
  }

  const { password, ...cambios } = data;
  if (password !== undefined) {
    cambios.passwordHash = await bcrypt.hash(password, BCRYPT_COST);
  }

  return usuarioRepository.update(id, cambios);
}
