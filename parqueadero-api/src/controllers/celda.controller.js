import * as celdaService from '../services/celda.service.js';
import { sendPage } from '../utils/paginacion.util.js';

export async function listarCeldas(req, res) {
  const { celdas, total, page, perPage } = await celdaService.listarCeldas(req.query);
  sendPage(res, celdas, { page, perPage, total });
}

export async function obtenerCeldaPorId(req, res) {
  const celda = await celdaService.obtenerCeldaPorId(req.params.id);
  res.status(200).json(celda);
}

export async function crearCelda(req, res) {
  const celda = await celdaService.crearCelda(req.body);
  res.status(201).json(celda);
}

export async function actualizarCelda(req, res) {
  const celda = await celdaService.actualizarCelda(req.params.id, req.body);
  res.status(200).json(celda);
}

export async function marcarMantenimiento(req, res) {
  const celda = await celdaService.marcarMantenimiento(req.params.id);
  res.status(200).json(celda);
}

export async function volverALibre(req, res) {
  const celda = await celdaService.volverALibre(req.params.id);
  res.status(200).json(celda);
}
