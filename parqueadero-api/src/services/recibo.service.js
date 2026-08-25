import { obtenerEstablecimiento } from './establecimiento.service.js';
import { formatearDuracion } from '../utils/duracion.util.js';

// Función pura (sin I/O, no toca Prisma): arma el recibo listo para
// imprimir a partir de un Ticket de dominio ya cargado con sus relaciones
// (vehiculo, celda, pago, operadorSalida). null si el ticket sigue ABIERTO
// (todavía no hay horaSalida, valorTotal ni consecutivo que mostrar).
export function construirRecibo(ticket) {
  if (!ticket.horaSalida) {
    return null;
  }

  return {
    consecutivo: ticket.reciboConsecutivo,
    fechaEmision: ticket.horaSalida,
    establecimiento: obtenerEstablecimiento(),
    placa: ticket.vehiculo.placa,
    tipoVehiculo: ticket.vehiculo.tipo,
    celda: ticket.celda.codigo,
    horaEntrada: ticket.horaEntrada,
    horaSalida: ticket.horaSalida,
    tiempoTotal: formatearDuracion(ticket.horaEntrada, ticket.horaSalida),
    desglose: ticket.desglose,
    total: ticket.valorTotal,
    metodoPago: ticket.pago?.metodo ?? null,
    operador: ticket.operadorSalida?.nombre ?? null,
  };
}
