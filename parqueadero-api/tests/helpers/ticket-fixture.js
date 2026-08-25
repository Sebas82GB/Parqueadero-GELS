import { randomUUID } from 'node:crypto';
import { prisma } from '../../src/config/database.js';
import { createCeldaInDb } from './celda-fixture.js';
import { createVehiculoInDb } from './vehiculo-fixture.js';
import { createTarifaInDb } from './tarifa-fixture.js';
import { createHorarioInDb } from './horario-fixture.js';
import { createUsuarioInDb } from './usuario-fixture.js';

function codigoUnico() {
  return `T-TEST-${randomUUID().slice(0, 8).toUpperCase()}`;
}

export function buildEntradaPayload(overrides = {}) {
  return {
    placa: `T${randomUUID().slice(0, 6).toUpperCase()}`,
    tipoVehiculo: 'CARRO',
    ...overrides,
  };
}

// Crea (si no se pasan) un vehículo, una celda OCUPADA, una tarifa vigente y
// un operador, y con eso un ticket ABIERTO. Acepta `horaEntrada` explícito
// para que los tests de salida controlen la duración de la estadía.
export async function createTicketInDb(overrides = {}) {
  const vehiculo = overrides.vehiculoId
    ? { id: overrides.vehiculoId }
    : await createVehiculoInDb({ tipo: overrides.tipoVehiculo ?? 'CARRO' });

  const celda = overrides.celdaId
    ? { id: overrides.celdaId }
    : await createCeldaInDb({
        tipoPermitido: overrides.tipoVehiculo ?? 'CARRO',
        estado: 'OCUPADA',
      });

  const tarifa = overrides.tarifaId
    ? { id: overrides.tarifaId }
    : await createTarifaInDb({ tipoVehiculo: overrides.tipoVehiculo ?? 'CARRO' });

  const horario = overrides.horarioId ? { id: overrides.horarioId } : await createHorarioInDb();

  const operador = overrides.operadorEntradaId
    ? { usuario: { id: overrides.operadorEntradaId } }
    : await createUsuarioInDb({ rol: 'OPERADOR' });

  const { tipoVehiculo, vehiculoId, celdaId, tarifaId, horarioId, operadorEntradaId, ...resto } =
    overrides;

  return prisma.ticket.create({
    data: {
      codigo: codigoUnico(),
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      horarioId: horario.id,
      operadorEntradaId: operadorEntradaId ?? operador.usuario.id,
      horaEntrada: new Date(),
      estado: 'ABIERTO',
      ...resto,
    },
  });
}
