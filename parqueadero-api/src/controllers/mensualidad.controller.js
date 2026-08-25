import * as mensualidadService from '../services/mensualidad.service.js';

export async function listarMensualidades(req, res) {
  const { mensualidades, total, page, perPage } = await mensualidadService.listarMensualidades(
    req.query,
  );
  res.status(200).json({ data: mensualidades, meta: { page, perPage, total } });
}

export async function obtenerMensualidadPorId(req, res) {
  const mensualidad = await mensualidadService.obtenerMensualidadPorId(req.params.id);
  res.status(200).json(mensualidad);
}

export async function crearMensualidad(req, res) {
  const mensualidad = await mensualidadService.crearMensualidad(req.body);
  res.status(201).json(mensualidad);
}

export async function actualizarMensualidad(req, res) {
  const mensualidad = await mensualidadService.actualizarMensualidad(req.params.id, req.body);
  res.status(200).json(mensualidad);
}

export async function pagarMensualidad(req, res) {
  const mensualidad = await mensualidadService.pagarMensualidad(req.params.id, req.body, {
    usuarioId: req.user.id,
  });
  res.status(200).json(mensualidad);
}

export async function cancelarMensualidad(req, res) {
  const mensualidad = await mensualidadService.cancelarMensualidad(req.params.id);
  res.status(200).json(mensualidad);
}
