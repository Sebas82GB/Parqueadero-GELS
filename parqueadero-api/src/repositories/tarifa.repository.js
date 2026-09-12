import { prisma } from '../config/database.js';
import { Tarifa } from '../models/tarifa.js';
import { ConflictError } from '../errors/index.js';
import { toSkipTake } from '../utils/paginacion.util.js';

function buildWhere({ tipoVehiculo, vigente, ahora }) {
  return {
    ...(tipoVehiculo !== undefined && { tipoVehiculo }),
    ...(vigente === true && {
      vigenteDesde: { lte: ahora },
      OR: [{ vigenteHasta: null }, { vigenteHasta: { gt: ahora } }],
    }),
    ...(vigente === false && {
      OR: [{ vigenteDesde: { gt: ahora } }, { vigenteHasta: { lte: ahora } }],
    }),
  };
}

export async function findMany({ tipoVehiculo, vigente, page, perPage, ahora = new Date() }) {
  const where = buildWhere({ tipoVehiculo, vigente, ahora });

  const [records, total] = await Promise.all([
    prisma.tarifa.findMany({
      where,
      orderBy: { vigenteDesde: 'desc' },
      ...toSkipTake(page, perPage),
    }),
    prisma.tarifa.count({ where }),
  ]);

  return { items: records.map(Tarifa.toDomain), total };
}

export async function findById(id) {
  const record = await prisma.tarifa.findUnique({ where: { id } });
  return record ? Tarifa.toDomain(record) : null;
}

export async function findVigenteByTipo(tipoVehiculo, fecha) {
  const record = await prisma.tarifa.findFirst({
    where: {
      tipoVehiculo,
      vigenteDesde: { lte: fecha },
      OR: [{ vigenteHasta: null }, { vigenteHasta: { gt: fecha } }],
    },
    orderBy: { vigenteDesde: 'desc' },
  });
  return record ? Tarifa.toDomain(record) : null;
}

// Crear una tarifa nueva de un tipo cierra automáticamente la vigente
// anterior del mismo tipo (le pone vigenteHasta). El updateMany cierra 0 o 1
// filas y nunca falla si no había ninguna vigente, así que no hace falta un
// check previo: la transacción solo garantiza que ambos pasos ocurran juntos.
export async function crearConAutoCierre({
  tipoVehiculo,
  valorMinuto,
  valorPlena,
  valorNocturna,
  valorMes,
  vigenteDesde,
}) {
  return prisma.$transaction(async (tx) => {
    await tx.tarifa.updateMany({
      where: { tipoVehiculo, vigenteHasta: null },
      data: { vigenteHasta: vigenteDesde },
    });

    const record = await tx.tarifa.create({
      data: Tarifa.toPersistence({
        tipoVehiculo,
        valorMinuto,
        valorPlena,
        valorNocturna,
        valorMes,
        vigenteDesde,
      }),
    });
    return Tarifa.toDomain(record);
  });
}

// Guardia de concurrencia: solo cierra si seguía vigente. Si otra petición ya
// la cerró entre el findById del servicio y este update, count queda en 0.
export async function cerrar(id, vigenteHasta) {
  const { count } = await prisma.tarifa.updateMany({
    where: { id, vigenteHasta: null },
    data: { vigenteHasta },
  });

  if (count === 0) {
    throw new ConflictError('La tarifa ya está cerrada', 'TARIFA_YA_CERRADA');
  }

  return findById(id);
}
