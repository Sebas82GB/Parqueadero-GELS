import { prisma } from '../../src/config/database.js';

export async function resetCeldas() {
  await prisma.celda.deleteMany({});
}

// Los refresh tokens tienen FK hacia usuarios: siempre hay que borrarlos
// antes de resetUsuarios().
export async function resetRefreshTokens() {
  await prisma.refreshToken.deleteMany({});
}

export async function resetUsuarios() {
  await prisma.usuario.deleteMany({});
}

export async function resetAnulaciones() {
  await prisma.anulacion.deleteMany({});
}

export async function resetPagos() {
  await prisma.pago.deleteMany({});
}

export async function resetTickets() {
  await prisma.ticket.deleteMany({});
}

export async function resetMensualidades() {
  await prisma.mensualidad.deleteMany({});
}

export async function resetTurnos() {
  await prisma.turno.deleteMany({});
}

export async function resetVehiculos() {
  await prisma.vehiculo.deleteMany({});
}

export async function resetTarifas() {
  await prisma.tarifa.deleteMany({});
}

export async function resetHorariosOperacion() {
  await prisma.horarioOperacion.deleteMany({});
}

// Orden obligado por las FK (todas Restrict): hijos antes que padres.
// No toca celdas/tarifas/usuarios: cada archivo decide si además los limpia.
export async function resetOperacion() {
  await resetAnulaciones();
  await resetPagos();
  await resetTickets();
  await resetMensualidades();
  await resetTurnos();
  await resetVehiculos();
}

export async function disconnectDb() {
  await prisma.$disconnect();
}
