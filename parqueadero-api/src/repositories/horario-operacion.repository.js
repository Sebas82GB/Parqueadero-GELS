import { prisma } from '../config/database.js';
import { HorarioOperacion } from '../models/horario-operacion.js';
import { ConflictError } from '../errors/index.js';

function buildWhere({ vigente, ahora }) {
  return {
    ...(vigente === true && {
      vigenteDesde: { lte: ahora },
      OR: [{ vigenteHasta: null }, { vigenteHasta: { gt: ahora } }],
    }),
    ...(vigente === false && {
      OR: [{ vigenteDesde: { gt: ahora } }, { vigenteHasta: { lte: ahora } }],
    }),
  };
}

export async function findMany({ vigente, page, perPage, ahora = new Date() }) {
  const where = buildWhere({ vigente, ahora });

  const [records, total] = await Promise.all([
    prisma.horarioOperacion.findMany({
      where,
      orderBy: { vigenteDesde: 'desc' },
      skip: (page - 1) * perPage,
      take: perPage,
    }),
    prisma.horarioOperacion.count({ where }),
  ]);

  return { items: records.map(HorarioOperacion.toDomain), total };
}

export async function findById(id) {
  const record = await prisma.horarioOperacion.findUnique({ where: { id } });
  return record ? HorarioOperacion.toDomain(record) : null;
}

// Sin discriminador: a diferencia de Tarifa (una vigencia por tipoVehiculo),
// solo existe un horario vigente global a la vez.
export async function findVigente(fecha) {
  const record = await prisma.horarioOperacion.findFirst({
    where: {
      vigenteDesde: { lte: fecha },
      OR: [{ vigenteHasta: null }, { vigenteHasta: { gt: fecha } }],
    },
    orderBy: { vigenteDesde: 'desc' },
  });
  return record ? HorarioOperacion.toDomain(record) : null;
}

// Crear un horario nuevo cierra automáticamente el vigente anterior (le pone
// vigenteHasta). El updateMany cierra 0 o 1 filas y nunca falla si no había
// ninguna vigente, así que no hace falta un check previo: la transacción
// solo garantiza que ambos pasos ocurran juntos.
export async function crearConAutoCierre({ apertura, cierre, vigenteDesde }) {
  return prisma.$transaction(async (tx) => {
    await tx.horarioOperacion.updateMany({
      where: { vigenteHasta: null },
      data: { vigenteHasta: vigenteDesde },
    });

    const record = await tx.horarioOperacion.create({
      data: HorarioOperacion.toPersistence({ apertura, cierre, vigenteDesde }),
    });
    return HorarioOperacion.toDomain(record);
  });
}

// Guardia de concurrencia: solo cierra si seguía vigente. Si otra petición ya
// lo cerró entre el findById del servicio y este update, count queda en 0.
export async function cerrar(id, vigenteHasta) {
  const { count } = await prisma.horarioOperacion.updateMany({
    where: { id, vigenteHasta: null },
    data: { vigenteHasta },
  });

  if (count === 0) {
    throw new ConflictError('El horario ya está cerrado', 'HORARIO_YA_CERRADO');
  }

  return findById(id);
}
