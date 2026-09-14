import * as tarifaService from '../services/tarifa.service.js';
import { sendPage } from '../utils/paginacion.util.js';

export async function listarTarifas(req, res) {
  const { tarifas, total, page, perPage } = await tarifaService.listarTarifas(req.query);
  sendPage(res, tarifas, { page, perPage, total });
}

export async function obtenerTarifaPorId(req, res) {
  const tarifa = await tarifaService.obtenerTarifaPorId(req.params.id);
  res.status(200).json(tarifa);
}

export async function crearTarifa(req, res) {
  const tarifa = await tarifaService.crearTarifa(req.body);
  res.status(201).json(tarifa);
}

export async function cerrarTarifa(req, res) {
  const tarifa = await tarifaService.cerrarTarifa(req.params.id);
  res.status(200).json(tarifa);
}

export async function actualizarTarifa(req, res) {
  const tarifa = await tarifaService.actualizarTarifa(req.params.id, req.body);
  res.status(200).json(tarifa);
}

export async function simularTarifa(req, res) {
  const resultado = await tarifaService.simularTarifa(req.body);
  res.status(200).json(resultado);
}
