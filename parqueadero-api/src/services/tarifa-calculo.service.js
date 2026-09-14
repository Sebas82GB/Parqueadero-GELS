import { UnprocessableEntityError } from '../errors/index.js';
import { bogotaParts, horaInstant, MINUTO_MS, HORA_MS } from '../utils/bogota-time.js';

const BLOQUE_MS = 6 * HORA_MS;
const MAX_BLOQUES_POR_DIA = 2;

function aperturaInstant(year, month, day, horario) {
  return horaInstant(year, month, day, horario.apertura);
}

function cierreInstant(year, month, day, horario) {
  return horaInstant(year, month, day, horario.cierre);
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
  const { year, month, day } = bogotaParts(horaEntrada);
  const aperturaHoy = aperturaInstant(year, month, day, horario);
  const cierreHoy = cierreInstant(year, month, day, horario);
  let diaAncla =
    horaEntrada < cierreHoy ? aperturaHoy : aperturaInstant(year, month, day + 1, horario);
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
