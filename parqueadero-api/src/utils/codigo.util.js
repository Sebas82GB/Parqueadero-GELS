import { randomUUID } from 'node:crypto';

export function generarCodigoTicket() {
  const fecha = new Date().toISOString().slice(2, 10).replaceAll('-', '');
  const sufijo = randomUUID().slice(0, 6).toUpperCase();
  return `T-${fecha}-${sufijo}`;
}
