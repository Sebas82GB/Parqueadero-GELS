import { Prisma } from '@prisma/client';
import { prisma } from '../config/database.js';
import { Vehiculo } from '../models/vehiculo.js';
import { ConflictError } from '../errors/index.js';

export async function findById(id) {
  const record = await prisma.vehiculo.findUnique({ where: { id } });
  return record ? Vehiculo.toDomain(record) : null;
}

export async function findByPlaca(placa) {
  const record = await prisma.vehiculo.findUnique({ where: { placa } });
  return record ? Vehiculo.toDomain(record) : null;
}

// Find-or-create atómico por placa: si ya existe, se ignora el tipo/dueño
// del payload y se conserva lo que ya estaba guardado (update: {}).
export async function upsertByPlaca({ placa, tipo, propietarioNombre, propietarioTelefono }) {
  try {
    const record = await prisma.vehiculo.upsert({
      where: { placa },
      update: {},
      create: Vehiculo.toPersistence({ placa, tipo, propietarioNombre, propietarioTelefono }),
    });
    return Vehiculo.toDomain(record);
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
      throw new ConflictError(
        `Ya existe un vehículo con la placa "${placa}"`,
        'VEHICULO_PLACA_DUPLICADA',
      );
    }
    throw err;
  }
}
