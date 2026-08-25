import { prisma } from '../config/database.js';
import { Mensualidad } from '../models/mensualidad.js';
import { ConflictError } from '../errors/index.js';

const UN_DIA_MS = 24 * 60 * 60 * 1000;

function buildWhere({ estadoPago, placa, vigencia, diasPorVencer, ahora }) {
  const limite = new Date(ahora.getTime() + diasPorVencer * UN_DIA_MS);

  const porVigencia = {
    VIGENTE: {
      estadoPago: { not: 'CANCELADA' },
      fechaInicio: { lte: ahora },
      fechaFin: { gte: ahora },
    },
    POR_VENCER: {
      estadoPago: { not: 'CANCELADA' },
      fechaFin: { gte: ahora, lte: limite },
    },
    VENCIDA: {
      estadoPago: { not: 'CANCELADA' },
      fechaFin: { lt: ahora },
    },
  };

  return {
    ...(estadoPago !== undefined && { estadoPago }),
    ...(placa !== undefined && { vehiculo: { placa } }),
    ...(vigencia !== undefined && porVigencia[vigencia]),
  };
}

export async function findMany({
  estadoPago,
  placa,
  vigencia,
  diasPorVencer,
  page,
  perPage,
  ahora = new Date(),
}) {
  const where = buildWhere({ estadoPago, placa, vigencia, diasPorVencer, ahora });

  const [records, total] = await Promise.all([
    prisma.mensualidad.findMany({
      where,
      include: { vehiculo: true },
      orderBy: { fechaFin: 'desc' },
      skip: (page - 1) * perPage,
      take: perPage,
    }),
    prisma.mensualidad.count({ where }),
  ]);

  return { items: records.map(Mensualidad.toDomain), total };
}

export async function findById(id) {
  const record = await prisma.mensualidad.findUnique({ where: { id } });
  return record ? Mensualidad.toDomain(record) : null;
}

// Una mensualidad CANCELADA no debe seguir cubriendo la estadía aunque sus
// fechas todavía la incluyan; NO_PAGADA sí cubre (CLAUDE.md §5: "no altera
// el cobro por estadía cuando está sin pagar").
export async function findVigenteByVehiculo(vehiculoId, fecha) {
  const record = await prisma.mensualidad.findFirst({
    where: {
      vehiculoId,
      estadoPago: { not: 'CANCELADA' },
      fechaInicio: { lte: fecha },
      fechaFin: { gte: fecha },
    },
    orderBy: { fechaFin: 'desc' },
  });
  return record ? Mensualidad.toDomain(record) : null;
}

// Usado por ticket.service.registrarEntrada para bloquear la celda de una
// mensualidad vigente a cualquier vehículo que no sea su dueño.
export async function findVigenteByCelda(celdaId, fecha) {
  const record = await prisma.mensualidad.findFirst({
    where: {
      celdaId,
      estadoPago: { not: 'CANCELADA' },
      fechaInicio: { lte: fecha },
      fechaFin: { gte: fecha },
    },
    orderBy: { fechaFin: 'desc' },
  });
  return record ? Mensualidad.toDomain(record) : null;
}

// Check-then-act, mismo nivel de riesgo de carrera ya aceptado en el
// proyecto para turno/celda: crear/editar mensualidades es una acción
// administrativa infrecuente, no un flujo de alta concurrencia.
export async function existsSolapada({ vehiculoId, fechaInicio, fechaFin, excludeId } = {}) {
  const count = await prisma.mensualidad.count({
    where: {
      vehiculoId,
      estadoPago: { not: 'CANCELADA' },
      fechaInicio: { lte: fechaFin },
      fechaFin: { gte: fechaInicio },
      ...(excludeId !== undefined && { id: { not: excludeId } }),
    },
  });
  return count > 0;
}

export async function create(data) {
  const record = await prisma.mensualidad.create({ data: Mensualidad.toPersistence(data) });
  return Mensualidad.toDomain(record);
}

export async function update(id, data) {
  const record = await prisma.mensualidad.update({
    where: { id },
    data: Mensualidad.toPersistence(data),
  });
  return Mensualidad.toDomain(record);
}

// El Pago se crea inline dentro de la misma transacción que marca la
// mensualidad como PAGADA, igual patrón que
// ticket.repository.registrarSalidaTransaccional. El updateMany guardado
// cubre la condición de carrera entre el check del servicio y esta escritura.
export async function pagarTransaccional({ mensualidadId, fechaPago, pago }) {
  return prisma.$transaction(async (tx) => {
    const { count } = await tx.mensualidad.updateMany({
      where: { id: mensualidadId, estadoPago: 'NO_PAGADA' },
      data: Mensualidad.toPersistence({ estadoPago: 'PAGADA', fechaPago }),
    });
    if (count === 0) {
      throw new ConflictError(
        'La mensualidad ya no está pendiente de pago',
        'MENSUALIDAD_NO_PENDIENTE',
      );
    }

    await tx.pago.create({ data: { mensualidadId, ...pago } });

    const record = await tx.mensualidad.findUnique({ where: { id: mensualidadId } });
    return Mensualidad.toDomain(record);
  });
}

export async function cancelar(id) {
  const { count } = await prisma.mensualidad.updateMany({
    where: { id, estadoPago: { not: 'CANCELADA' } },
    data: { estadoPago: 'CANCELADA' },
  });

  if (count === 0) {
    throw new ConflictError('La mensualidad ya está cancelada', 'MENSUALIDAD_YA_CANCELADA');
  }

  return findById(id);
}
