import { Prisma } from '@prisma/client';
import { prisma } from '../config/database.js';
import { Ticket } from '../models/ticket.js';
import { ConflictError } from '../errors/index.js';

const DETALLE = {
  vehiculo: true,
  celda: true,
  tarifa: true,
  horario: true,
  operadorSalida: true,
  pago: true,
};

// tickets tiene tres constraints únicos alcanzables desde acá: `codigo`, el
// índice parcial "un solo ticket ABIERTO por vehículo" (agregado a mano en
// SQL, Prisma no lo conoce como campo) y `pagos_ticket_id_key` del pago
// anidado. err.meta.target llega como array de campos o como string crudo
// del nombre del índice según cuál sea — hay que normalizar antes de comparar.
function traducirErrorUnicidad(err, { codigo } = {}) {
  if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
    const target = Array.isArray(err.meta?.target)
      ? err.meta.target.join(',')
      : String(err.meta?.target ?? '');
    const t = target.toLowerCase().replaceAll('_', '');

    if (t.includes('vehiculoid')) {
      throw new ConflictError(
        'El vehículo ya tiene un ticket abierto',
        'VEHICULO_CON_TICKET_ABIERTO',
      );
    }
    if (t.includes('ticketid')) {
      throw new ConflictError('El ticket ya tiene un pago registrado', 'TICKET_YA_TIENE_PAGO');
    }
    if (t.includes('codigo')) {
      throw new ConflictError(
        `Ya existe un ticket con el código "${codigo}"`,
        'TICKET_CODIGO_DUPLICADO',
      );
    }
    throw new ConflictError(
      'Conflicto de unicidad al registrar el ticket',
      'TICKET_CONFLICTO_UNICIDAD',
    );
  }
  throw err;
}

function buildWhere({ estado, vehiculoId, celdaId, placa, desde, hasta }) {
  return {
    ...(estado !== undefined && { estado }),
    ...(vehiculoId !== undefined && { vehiculoId }),
    ...(celdaId !== undefined && { celdaId }),
    ...(placa !== undefined && { vehiculo: { placa } }),
    ...((desde !== undefined || hasta !== undefined) && {
      horaEntrada: {
        ...(desde !== undefined && { gte: desde }),
        ...(hasta !== undefined && { lte: hasta }),
      },
    }),
  };
}

export async function findMany({
  estado,
  vehiculoId,
  celdaId,
  placa,
  desde,
  hasta,
  page,
  perPage,
}) {
  const where = buildWhere({ estado, vehiculoId, celdaId, placa, desde, hasta });

  const [records, total] = await Promise.all([
    prisma.ticket.findMany({
      where,
      include: { vehiculo: true, celda: true },
      orderBy: { horaEntrada: 'desc' },
      skip: (page - 1) * perPage,
      take: perPage,
    }),
    prisma.ticket.count({ where }),
  ]);

  return { items: records.map(Ticket.toDomain), total };
}

export async function findById(id) {
  const record = await prisma.ticket.findUnique({ where: { id } });
  return record ? Ticket.toDomain(record) : null;
}

export async function findByIdConDetalle(id) {
  const record = await prisma.ticket.findUnique({ where: { id }, include: DETALLE });
  return record ? Ticket.toDomain(record) : null;
}

export async function findAbiertoByVehiculo(vehiculoId) {
  const record = await prisma.ticket.findFirst({ where: { vehiculoId, estado: 'ABIERTO' } });
  return record ? Ticket.toDomain(record) : null;
}

// Ticket no tiene turnoId propio (solo Pago lo tiene, y un ticket cerrado
// por mensualidad vigente nunca genera Pago). Para el arqueo de un turno se
// cuenta por operador + rango de horaSalida en vez de por Pago, así no
// quedan ciegos los cierres en $0. `hasta` en null (turno todavía abierto)
// no pone tope superior: cuenta hasta el momento de la consulta.
export async function countCerradosPorOperadorEnRango({ operadorId, desde, hasta }) {
  return prisma.ticket.count({
    where: {
      operadorSalidaId: operadorId,
      horaSalida: { gte: desde, ...(hasta != null && { lte: hasta }) },
    },
  });
}

export async function crearEntradaTransaccional(data) {
  try {
    return await prisma.$transaction(async (tx) => {
      const { count } = await tx.celda.updateMany({
        where: { id: data.celdaId, estado: 'LIBRE' },
        data: { estado: 'OCUPADA' },
      });
      if (count === 0) {
        throw new ConflictError('La celda ya no está libre', 'CELDA_OCUPADA');
      }

      const record = await tx.ticket.create({
        data: Ticket.toPersistence(data),
        include: DETALLE,
      });
      return Ticket.toDomain(record);
    });
  } catch (err) {
    traducirErrorUnicidad(err, { codigo: data.codigo });
  }
}

export async function registrarSalidaTransaccional({
  ticketId,
  celdaId,
  horaSalida,
  valorTotal,
  desglose,
  operadorSalidaId,
  pago,
}) {
  try {
    return await prisma.$transaction(async (tx) => {
      const { count } = await tx.ticket.updateMany({
        where: { id: ticketId, estado: 'ABIERTO' },
        data: Ticket.toPersistence({
          horaSalida,
          valorTotal,
          desglose,
          estado: 'PAGADO',
          operadorSalidaId,
        }),
      });
      if (count === 0) {
        throw new ConflictError('El ticket ya no está abierto', 'TICKET_NO_ABIERTO');
      }

      await tx.celda.update({ where: { id: celdaId }, data: { estado: 'LIBRE' } });

      if (pago) {
        await tx.pago.create({ data: { ticketId, ...pago } });
      }

      // Secuencia real de Postgres: nextval() es atómica e independiente del
      // rollback de esta transacción, así que dos salidas concurrentes nunca
      // reciben el mismo consecutivo (a diferencia de un contador calculado
      // en JS, que sí podría repetirse bajo carrera).
      await tx.$executeRaw`UPDATE "tickets" SET "recibo_consecutivo" = nextval('recibo_consecutivo_seq')::integer WHERE "id" = ${ticketId}::uuid`;

      const record = await tx.ticket.findUnique({ where: { id: ticketId }, include: DETALLE });
      return Ticket.toDomain(record);
    });
  } catch (err) {
    traducirErrorUnicidad(err, {});
  }
}

export async function anularTransaccional({ ticketId, celdaId, motivo, anuladoPorId, anuladoEn }) {
  return prisma.$transaction(async (tx) => {
    const { count } = await tx.ticket.updateMany({
      where: { id: ticketId, estado: 'ABIERTO' },
      data: Ticket.toPersistence({
        estado: 'ANULADO',
        motivoAnulacion: motivo,
        anuladoPorId,
        anuladoEn,
      }),
    });
    if (count === 0) {
      throw new ConflictError('El ticket ya no está abierto', 'TICKET_NO_ABIERTO');
    }

    await tx.celda.update({ where: { id: celdaId }, data: { estado: 'LIBRE' } });

    const record = await tx.ticket.findUnique({ where: { id: ticketId }, include: DETALLE });
    return Ticket.toDomain(record);
  });
}

export async function marcarEntregado(id, { entregadoPorId, entregadoEn }) {
  const { count } = await prisma.ticket.updateMany({
    where: { id, estado: 'PAGADO' },
    data: Ticket.toPersistence({ estado: 'ENTREGADO', entregadoPorId, entregadoEn }),
  });
  if (count === 0) {
    throw new ConflictError('El ticket no está pagado', 'TICKET_NO_PAGADO');
  }

  const record = await prisma.ticket.findUnique({ where: { id }, include: DETALLE });
  return Ticket.toDomain(record);
}
