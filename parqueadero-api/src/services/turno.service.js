import * as turnoRepository from '../repositories/turno.repository.js';
import * as pagoRepository from '../repositories/pago.repository.js';
import * as ticketRepository from '../repositories/ticket.repository.js';
import { NotFoundError, ConflictError, ForbiddenError } from '../errors/index.js';

// Objeto de resumen compartido por cerrarTurno (arqueo final, recién
// cerrado) y obtenerArqueo (parcial en vivo o final): misma forma en los dos
// casos para que el frontend no tenga que distinguir la respuesta.
function armarArqueo(turno, { totalesPorMetodo, ticketsCerrados }) {
  const totalRecaudado = Object.values(totalesPorMetodo).reduce((a, b) => a + b, 0);
  const efectivoEsperado = turno.baseInicial + totalesPorMetodo.EFECTIVO;

  return {
    turnoId: turno.id,
    operadorId: turno.operadorId,
    estado: turno.estado,
    apertura: turno.apertura,
    cierre: turno.cierre,
    baseInicial: turno.baseInicial,
    totalesPorMetodo,
    totalRecaudado,
    ticketsCerrados,
    efectivoEsperado,
    efectivoContado: turno.efectivoContado,
    diferencia: turno.diferencia,
  };
}

export async function abrirTurno({ baseInicial }, { operadorId }) {
  const turnoAbierto = await turnoRepository.findAbiertoByOperador(operadorId);
  if (turnoAbierto) {
    throw new ConflictError('Ya tiene un turno abierto', 'TURNO_YA_ABIERTO');
  }

  return turnoRepository.create({ operadorId, baseInicial });
}

export async function cerrarTurno(id, { efectivoContado }, { usuarioId, rol }) {
  const turno = await turnoRepository.findById(id);
  if (!turno) {
    throw new NotFoundError(`Turno con id "${id}" no encontrado`, 'TURNO_NO_ENCONTRADO');
  }

  if (turno.estado !== 'ABIERTO') {
    throw new ConflictError('El turno ya está cerrado', 'TURNO_YA_CERRADO');
  }

  if (turno.operadorId !== usuarioId && rol !== 'ADMIN') {
    throw new ForbiddenError('No puede cerrar el turno de otro operador', 'TURNO_AJENO');
  }

  const totalesPorMetodo = await pagoRepository.sumPorMetodoByTurno(id);
  const totalRecaudado = Object.values(totalesPorMetodo).reduce((a, b) => a + b, 0);
  const efectivoEsperado = turno.baseInicial + totalesPorMetodo.EFECTIVO;
  // Sobrante > 0, faltante < 0, cuadre exacto = 0 — se guarda siempre, nunca
  // se corrige ni se oculta.
  const diferencia = efectivoContado - efectivoEsperado;
  const cierre = new Date();

  const turnoCerrado = await turnoRepository.cerrar(id, {
    cierre,
    totalRecaudado,
    efectivoContado,
    efectivoEsperado,
    diferencia,
  });

  const ticketsCerrados = await ticketRepository.countCerradosPorOperadorEnRango({
    operadorId: turno.operadorId,
    desde: turno.apertura,
    hasta: cierre,
  });

  return armarArqueo(turnoCerrado, { totalesPorMetodo, ticketsCerrados });
}

export async function obtenerArqueo(id, { usuarioId, rol }) {
  const turno = await turnoRepository.findById(id);
  if (!turno) {
    throw new NotFoundError(`Turno con id "${id}" no encontrado`, 'TURNO_NO_ENCONTRADO');
  }

  if (turno.operadorId !== usuarioId && rol !== 'ADMIN') {
    throw new ForbiddenError('No puede ver el arqueo del turno de otro operador', 'TURNO_AJENO');
  }

  const totalesPorMetodo = await pagoRepository.sumPorMetodoByTurno(id);
  const ticketsCerrados = await ticketRepository.countCerradosPorOperadorEnRango({
    operadorId: turno.operadorId,
    desde: turno.apertura,
    hasta: turno.cierre,
  });

  return armarArqueo(turno, { totalesPorMetodo, ticketsCerrados });
}

export async function listarTurnos(query, { usuarioId, rol }) {
  const { operadorId, estado, desde, hasta, page, perPage } = query;
  // Un OPERADOR nunca ve turnos ajenos, aunque pida explícitamente el
  // operadorId de otro: se fuerza el suyo en vez de rechazar la petición.
  const operadorFiltro = rol === 'OPERADOR' ? usuarioId : operadorId;

  const { items, total } = await turnoRepository.findMany({
    operadorId: operadorFiltro,
    estado,
    desde,
    hasta,
    page,
    perPage,
  });

  return { turnos: items, total, page, perPage };
}
