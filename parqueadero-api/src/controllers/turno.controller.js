import * as turnoService from '../services/turno.service.js';

export async function abrirTurno(req, res) {
  const turno = await turnoService.abrirTurno(req.body, { operadorId: req.user.id });
  res.status(201).json(turno);
}

export async function cerrarTurno(req, res) {
  const arqueo = await turnoService.cerrarTurno(req.params.id, req.body, {
    usuarioId: req.user.id,
    rol: req.user.rol,
  });
  res.status(200).json(arqueo);
}

export async function obtenerArqueo(req, res) {
  const arqueo = await turnoService.obtenerArqueo(req.params.id, {
    usuarioId: req.user.id,
    rol: req.user.rol,
  });
  res.status(200).json(arqueo);
}

export async function listarTurnos(req, res) {
  const { turnos, total, page, perPage } = await turnoService.listarTurnos(req.query, {
    usuarioId: req.user.id,
    rol: req.user.rol,
  });
  res.status(200).json({ data: turnos, meta: { page, perPage, total } });
}
