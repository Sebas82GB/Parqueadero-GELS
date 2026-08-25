import { obtenerEstablecimiento } from '../services/establecimiento.service.js';

export async function getEstablecimiento(req, res) {
  const establecimiento = obtenerEstablecimiento();
  res.status(200).json(establecimiento);
}
