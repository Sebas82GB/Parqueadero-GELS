import * as mensualidadRepository from '../repositories/mensualidad.repository.js';
import * as vehiculoRepository from '../repositories/vehiculo.repository.js';
import * as celdaRepository from '../repositories/celda.repository.js';
import * as turnoRepository from '../repositories/turno.repository.js';
import { NotFoundError, ConflictError } from '../errors/index.js';

export async function listarMensualidades(query) {
  const { estadoPago, placa, vigencia, diasPorVencer, page, perPage } = query;
  const { items, total } = await mensualidadRepository.findMany({
    estadoPago,
    placa,
    vigencia,
    diasPorVencer,
    page,
    perPage,
  });
  return { mensualidades: items, total, page, perPage };
}

export async function obtenerMensualidadPorId(id) {
  const mensualidad = await mensualidadRepository.findById(id);
  if (!mensualidad) {
    throw new NotFoundError(
      `Mensualidad con id "${id}" no encontrada`,
      'MENSUALIDAD_NO_ENCONTRADA',
    );
  }
  return mensualidad;
}

export async function crearMensualidad({
  placa,
  tipoVehiculo,
  propietarioNombre,
  propietarioTelefono,
  celdaId,
  fechaInicio,
  fechaFin,
  valorMensualidad,
}) {
  const vehiculo = await vehiculoRepository.upsertByPlaca({
    placa,
    tipo: tipoVehiculo,
    propietarioNombre,
    propietarioTelefono,
  });

  if (celdaId !== undefined) {
    const celda = await celdaRepository.findById(celdaId);
    if (!celda) {
      throw new NotFoundError(`Celda con id "${celdaId}" no encontrada`, 'CELDA_NO_ENCONTRADA');
    }
  }

  const solapada = await mensualidadRepository.existsSolapada({
    vehiculoId: vehiculo.id,
    fechaInicio,
    fechaFin,
  });
  if (solapada) {
    throw new ConflictError(
      'El vehículo ya tiene una mensualidad con fechas que se solapan',
      'MENSUALIDAD_SOLAPADA',
    );
  }

  return mensualidadRepository.create({
    vehiculoId: vehiculo.id,
    celdaId,
    fechaInicio,
    fechaFin,
    valorMensualidad,
  });
}

export async function actualizarMensualidad(id, patch) {
  const actual = await obtenerMensualidadPorId(id);

  if (actual.estadoPago === 'CANCELADA') {
    throw new ConflictError('La mensualidad está cancelada', 'MENSUALIDAD_CANCELADA');
  }

  if (patch.celdaId !== undefined) {
    const celda = await celdaRepository.findById(patch.celdaId);
    if (!celda) {
      throw new NotFoundError(
        `Celda con id "${patch.celdaId}" no encontrada`,
        'CELDA_NO_ENCONTRADA',
      );
    }
  }

  if (patch.fechaInicio !== undefined || patch.fechaFin !== undefined) {
    const fechaInicio = patch.fechaInicio ?? actual.fechaInicio;
    const fechaFin = patch.fechaFin ?? actual.fechaFin;
    const solapada = await mensualidadRepository.existsSolapada({
      vehiculoId: actual.vehiculoId,
      fechaInicio,
      fechaFin,
      excludeId: id,
    });
    if (solapada) {
      throw new ConflictError(
        'El vehículo ya tiene una mensualidad con fechas que se solapan',
        'MENSUALIDAD_SOLAPADA',
      );
    }
  }

  return mensualidadRepository.update(id, patch);
}

// El Pago queda atado al turno abierto de quien llama, así que solo puede
// pagar quien puede tener un turno abierto (OPERADOR, o ADMIN vía la misma
// excepción que ya existe para /tickets/:id/entregar).
export async function pagarMensualidad(id, { metodo }, { usuarioId }) {
  const mensualidad = await obtenerMensualidadPorId(id);

  if (mensualidad.estadoPago === 'CANCELADA') {
    throw new ConflictError('La mensualidad está cancelada', 'MENSUALIDAD_CANCELADA');
  }
  if (mensualidad.estadoPago === 'PAGADA') {
    throw new ConflictError('La mensualidad ya está pagada', 'MENSUALIDAD_YA_PAGADA');
  }

  const turno = await turnoRepository.findAbiertoByOperador(usuarioId);
  if (!turno) {
    throw new ConflictError('No tiene un turno abierto', 'OPERADOR_SIN_TURNO_ABIERTO');
  }

  return mensualidadRepository.pagarTransaccional({
    mensualidadId: id,
    fechaPago: new Date(),
    pago: { monto: mensualidad.valorMensualidad, metodo, turnoId: turno.id },
  });
}

export async function cancelarMensualidad(id) {
  await obtenerMensualidadPorId(id);
  return mensualidadRepository.cancelar(id);
}
