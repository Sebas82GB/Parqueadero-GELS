import * as usuarioService from '../services/usuario.service.js';

export async function listarUsuarios(req, res) {
  const { usuarios, total, page, perPage } = await usuarioService.listarUsuarios(req.query);
  res.status(200).json({ data: usuarios, meta: { page, perPage, total } });
}

export async function obtenerUsuarioPorId(req, res) {
  const usuario = await usuarioService.obtenerUsuarioPorId(req.params.id);
  res.status(200).json(usuario);
}

export async function crearUsuario(req, res) {
  const usuario = await usuarioService.crearUsuario(req.body);
  res.status(201).json(usuario);
}

export async function actualizarUsuario(req, res) {
  const usuario = await usuarioService.actualizarUsuario(req.params.id, req.body);
  res.status(200).json(usuario);
}
