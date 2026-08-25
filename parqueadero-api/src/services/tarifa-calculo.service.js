import { UnprocessableEntityError } from '../errors/index.js';

// Bogotá vive en UTC-5 todo el año (sin horario de verano desde 1993), así
// que la conversión es una resta fija de horas, no una zona horaria real.
const BOGOTA_OFFSET_MS = 5 * 60 * 60 * 1000;
const MINUTO_MS = 60 * 1000;
const HORA_MS = 60 * MINUTO_MS;
const BLOQUE_MS = 6 * HORA_MS;
const MAX_BLOQUES_POR_DIA = 2;

function bogotaParts(date) {
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

function aperturaInstant(year, month, day, horario) {
  const { hora, minuto } = parseHora(horario.apertura);
  return bogotaInstant(year, month, day, hora, minuto, 0);
}

function cierreInstant(year, month, day, horario) {
  const { hora, minuto } = parseHora(horario.cierre);
  return bogotaInstant(year, month, day, hora, minuto, 0);
}

// Próxima apertura Bogotá estrictamente después de `ancla`: mismo día
// calendario si `ancla` es antes de la apertura de ese día, si no, la del
// día siguiente.
function siguienteApertura(ancla, horario) {
  const { year, month, day } = bogotaParts(ancla);
  const aperturaHoy = aperturaInstant(year, month, day, horario);
  return ancla < aperturaHoy ? aperturaHoy : aperturaInstant(year, month, day + 1, horario);
}

// Una mensualidad con celdaId reserva una celda puntual: solo exime del cobro
// la estadía que ocurrió en esa celda. Si el vehículo parqueó en otra celda,
// la mensualidad no aplica y se cobra la estadía real. Una mensualidad sin
// celdaId (celdaId null) no está atada a una celda y exime en cualquiera.
function mensualidadVigente(mensualidad, horaEntrada, celdaId) {
  if (!mensualidad) return false;
  if (mensualidad.celdaId && mensualidad.celdaId !== celdaId) return false;
  return horaEntrada >= mensualidad.fechaInicio && horaEntrada <= mensualidad.fechaFin;
}

function validarRango(horaEntrada, horaSalida) {
  if (horaSalida <= horaEntrada) {
    throw new UnprocessableEntityError(
      'horaSalida debe ser posterior a horaEntrada',
      'RANGO_FECHAS_INVALIDO',
    );
  }
}

function calcularBloques({ horaEntrada, horaSalida, tarifa, horario }) {
  let t = horaEntrada;
  let diaAncla = horaEntrada;
  let cierreDia = cierreInstant(
    bogotaParts(diaAncla).year,
    bogotaParts(diaAncla).month,
    bogotaParts(diaAncla).day,
    horario,
  );
  let bloquesEnDia = 0;
  const grupos = [];
  let grupoActual = null;

  while (t < horaSalida) {
    if (t >= siguienteApertura(diaAncla, horario)) {
      const partes = bogotaParts(t);
      diaAncla = aperturaInstant(partes.year, partes.month, partes.day, horario);
      cierreDia = cierreInstant(partes.year, partes.month, partes.day, horario);
      bloquesEnDia = 0;
    }

    if (bloquesEnDia >= MAX_BLOQUES_POR_DIA || t >= cierreDia) {
      const siguiente = siguienteApertura(diaAncla, horario);
      t = siguiente < horaSalida ? siguiente : horaSalida;
      continue;
    }

    if (!grupoActual || grupoActual.diaAncla.getTime() !== diaAncla.getTime()) {
      grupoActual = { diaAncla, cierreDia, bloques: [] };
      grupos.push(grupoActual);
    }

    const finNatural = new Date(t.getTime() + BLOQUE_MS);
    // Un bloque nunca se muestra ni se cobra con un rango que se extienda
    // más allá del cierre: se trunca ahí si su fin natural cae después.
    const finTruncado = finNatural < cierreDia ? finNatural : cierreDia;
    const finEfectivo = finTruncado < horaSalida ? finTruncado : horaSalida;
    const minutos = Math.ceil((finEfectivo.getTime() - t.getTime()) / MINUTO_MS);
    const valorPlenaTope = Math.min(minutos * tarifa.valorMinuto, tarifa.valorPlena);

    grupoActual.bloques.push({ inicio: t, fin: finEfectivo, minutos, valorPlenaTope });
    bloquesEnDia += 1;
    t = finEfectivo;
  }

  const desglose = [];
  grupos.forEach((grupo, grupoIndex) => {
    // El último bloque cobrado de un día se vuelve nocturna si la salida
    // general ocurre después del cierre de ese día — sin importar si ese
    // bloque llegó a tocar la pared del cierre o solo agotó el tope de
    // MAX_BLOQUES_POR_DIA antes de llegar a él.
    const permanecioDespuesDeCierre = horaSalida > grupo.cierreDia;
    grupo.bloques.forEach((bloque, index) => {
      const esUltimoDelGrupo = index === grupo.bloques.length - 1;
      const nocturna = permanecioDespuesDeCierre && esUltimoDelGrupo;
      const valor = nocturna ? tarifa.valorNocturna : bloque.valorPlenaTope;
      const tipoCobro = nocturna
        ? 'NOCTURNA'
        : bloque.minutos * tarifa.valorMinuto >= tarifa.valorPlena
          ? 'PLENA'
          : 'PARCIAL';

      desglose.push({
        dia: grupoIndex + 1,
        bloqueNumero: index + 1,
        inicio: bloque.inicio.toISOString(),
        fin: bloque.fin.toISOString(),
        minutos: bloque.minutos,
        tipoCobro,
        valor,
      });
    });
  });

  const valorTotal = desglose.reduce((acumulado, bloque) => acumulado + bloque.valor, 0);
  return { valorTotal, desglose };
}

export function calcularTarifa({
  horaEntrada,
  horaSalida,
  tarifa,
  mensualidad = null,
  celdaId,
  valorManual,
  horario,
}) {
  validarRango(horaEntrada, horaSalida);

  if (mensualidadVigente(mensualidad, horaEntrada, celdaId)) {
    return { valorTotal: 0, desglose: [{ tipo: 'MENSUALIDAD', valor: 0 }] };
  }

  if (tarifa.tipoVehiculo === 'OTRO') {
    return { valorTotal: valorManual, desglose: [{ tipo: 'MANUAL', valor: valorManual }] };
  }

  return calcularBloques({ horaEntrada, horaSalida, tarifa, horario });
}

// Variante de calcularTarifa para vistas previas: nunca hay un valorManual
// todavía (el operador no lo ha digitado), así que en vez de exigirlo
// devuelve un indicador explícito de que el valor lo pone el operador.
// Comparte calcularBloques y mensualidadVigente con calcularTarifa: la
// lógica de cálculo real vive en un solo lugar.
export function previsualizarTarifa({
  horaEntrada,
  horaSalida,
  tarifa,
  mensualidad = null,
  celdaId,
  horario,
}) {
  validarRango(horaEntrada, horaSalida);

  if (mensualidadVigente(mensualidad, horaEntrada, celdaId)) {
    return { valorTotal: 0, desglose: [{ tipo: 'MENSUALIDAD', valor: 0 }] };
  }

  if (tarifa.tipoVehiculo === 'OTRO') {
    return {
      valorTotal: null,
      desglose: [
        {
          tipo: 'MANUAL',
          valor: null,
          motivo: 'El operador digita el valor al registrar la salida',
        },
      ],
    };
  }

  return calcularBloques({ horaEntrada, horaSalida, tarifa, horario });
}
