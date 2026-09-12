import * as horarioService from '../services/horario-operacion.service.js';
import { sendPage } from '../utils/paginacion.util.js';

export async function listarHorarios(req, res) {
  const { horarios, total, page, perPage } = await horarioService.listarHorarios(req.query);
  sendPage(res, horarios, { page, perPage, total });
}

export async function obtenerHorarioPorId(req, res) {
  const horario = await horarioService.obtenerHorarioPorId(req.params.id);
  res.status(200).json(horario);
}

export async function crearHorario(req, res) {
  const horario = await horarioService.crearHorario(req.body);
  res.status(201).json(horario);
}

export async function cerrarHorario(req, res) {
  const horario = await horarioService.cerrarHorario(req.params.id);
  res.status(200).json(horario);
}
