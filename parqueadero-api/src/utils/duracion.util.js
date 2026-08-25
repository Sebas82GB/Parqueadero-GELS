const MINUTO_MS = 60 * 1000;
const HORA_MS = 60 * MINUTO_MS;
const DIA_MS = 24 * HORA_MS;

// "45min" | "1h 30min" | "2h 0min" | "1d 3h 15min"
export function formatearDuracion(inicio, fin) {
  const totalMs = Math.max(0, fin.getTime() - inicio.getTime());
  const dias = Math.floor(totalMs / DIA_MS);
  const horas = Math.floor((totalMs % DIA_MS) / HORA_MS);
  const minutos = Math.floor((totalMs % HORA_MS) / MINUTO_MS);

  const partes = [];
  if (dias > 0) partes.push(`${dias}d`);
  if (dias > 0 || horas > 0) partes.push(`${horas}h`);
  partes.push(`${minutos}min`);

  return partes.join(' ');
}
