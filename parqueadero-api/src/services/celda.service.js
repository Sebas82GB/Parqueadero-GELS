import * as celdaRepository from '../repositories/celda.repository.js';
import { NotFoundError, ConflictError } from '../errors/index.js';

export async function listarCeldas(query) {
  const { zona, estado, tipoPermitido, page, perPage } = query;
  const { items, total } = await celdaRepository.findMany({
    zona,
    estado,
    tipoPermitido,
    page,
    perPage,
  });
  return { celdas: items, total, page, perPage };
}

export async function obtenerCeldaPorId(id) {
  const celda = await celdaRepository.findById(id);
  if (!celda) {
    throw new NotFoundError(`Celda con id "${id}" no encontrada`, 'CELDA_NO_ENCONTRADA');
  }
  return celda;
}

export async function crearCelda({ codigo, zona, tipoPermitido }) {
  const existente = await celdaRepository.findByCodigo(codigo);
  if (existente) {
    throw new ConflictError(
      `Ya existe una celda con el código "${codigo}"`,
      'CELDA_CODIGO_DUPLICADO',
    );
  }
  return celdaRepository.create({ codigo, zona, tipoPermitido });
}

export async function actualizarCelda(id, data) {
  const celda = await obtenerCeldaPorId(id);

  if (data.codigo !== undefined) {
    const existente = await celdaRepository.findByCodigo(data.codigo);
    if (existente && existente.id !== celda.id) {
      throw new ConflictError(
        `Ya existe una celda con el código "${data.codigo}"`,
        'CELDA_CODIGO_DUPLICADO',
      );
    }
  }

  return celdaRepository.update(id, data);
}

export async function marcarMantenimiento(id) {
  const celda = await obtenerCeldaPorId(id);

  if (celda.estado === 'OCUPADA') {
    throw new ConflictError(`La celda ${celda.codigo} ya está ocupada`, 'CELDA_OCUPADA');
  }
  if (celda.estado === 'MANTENIMIENTO') {
    throw new ConflictError(
      `La celda ${celda.codigo} ya está en mantenimiento`,
      'CELDA_ESTADO_INVALIDO',
    );
  }

  return celdaRepository.update(id, { estado: 'MANTENIMIENTO' });
}

export async function volverALibre(id) {
  const celda = await obtenerCeldaPorId(id);

  if (celda.estado === 'OCUPADA') {
    throw new ConflictError(
      `La celda ${celda.codigo} está ocupada y no puede liberarse manualmente`,
      'CELDA_OCUPADA',
    );
  }
  if (celda.estado === 'LIBRE') {
    throw new ConflictError(`La celda ${celda.codigo} ya está libre`, 'CELDA_ESTADO_INVALIDO');
  }

  return celdaRepository.update(id, { estado: 'LIBRE' });
}
