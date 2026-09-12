// Bogotá vive en UTC-5 todo el año (sin horario de verano desde 1993), así
// que la conversión es una resta fija de horas, no una zona horaria real.
// Compartido por tarifa-calculo.service.js (cortes de apertura/cierre por
// bloque) y turno.service.js (ventana de apertura/cierre automática de
// turno): los dos necesitan la misma conversión hora-local↔instante UTC.
const BOGOTA_OFFSET_MS = 5 * 60 * 60 * 1000;
export const MINUTO_MS = 60 * 1000;
export const HORA_MS = 60 * MINUTO_MS;

export function bogotaParts(date) {
  const shifted = new Date(date.getTime() - BOGOTA_OFFSET_MS);
  return {
    year: shifted.getUTCFullYear(),
    month: shifted.getUTCMonth(),
    day: shifted.getUTCDate(),
    hour: shifted.getUTCHours(),
    minute: shifted.getUTCMinutes(),
    second: shifted.getUTCSeconds(),
  };
}

function bogotaInstant(year, month, day, hour, minute, second) {
  return new Date(Date.UTC(year, month, day, hour, minute, second) + BOGOTA_OFFSET_MS);
}

// horario.apertura/horario.cierre llegan como strings "HH:mm" (hora local),
// tal como los expone HorarioOperacion.toDomain.
function parseHora(hhmm) {
  const [hora, minuto] = hhmm.split(':').map(Number);
  return { hora, minuto };
}

// Instante Bogotá de una hora "HH:mm" en un día calendario (Bogotá) dado.
export function horaInstant(year, month, day, hhmm) {
  const { hora, minuto } = parseHora(hhmm);
  return bogotaInstant(year, month, day, hora, minuto, 0);
}
