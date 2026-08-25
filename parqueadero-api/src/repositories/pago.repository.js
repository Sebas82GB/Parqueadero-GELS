import { prisma } from '../config/database.js';

// Postgres devuelve NULL (no 0) cuando SUM() no tiene filas que sumar.
export async function sumMontoValidoByTurno(turnoId) {
  const resultado = await prisma.pago.aggregate({
    _sum: { monto: true },
    where: { turnoId, estado: 'VALIDO' },
  });
  return resultado._sum.monto ?? 0;
}

// groupBy solo devuelve filas para los métodos que sí tienen pagos; se
// rellenan los otros en 0 para que el arqueo siempre tenga los tres.
export async function sumPorMetodoByTurno(turnoId) {
  const filas = await prisma.pago.groupBy({
    by: ['metodo'],
    where: { turnoId, estado: 'VALIDO' },
    _sum: { monto: true },
  });

  const totales = { EFECTIVO: 0, TARJETA: 0, TRANSFERENCIA: 0 };
  for (const fila of filas) {
    totales[fila.metodo] = fila._sum.monto ?? 0;
  }
  return totales;
}
