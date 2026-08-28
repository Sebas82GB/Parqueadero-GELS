import * as turnoRepository from '../repositories/turno.repository.js';
import * as pagoRepository from '../repositories/pago.repository.js';
import * as ticketRepository from '../repositories/ticket.repository.js';
import * as horarioRepository from '../repositories/horario-operacion.repository.js';
import * as usuarioRepository from '../repositories/usuario.repository.js';
import {
  NotFoundError,
  ConflictError,
  ForbiddenError,
  UnprocessableEntityError,
} from '../errors/index.js';
import { bogotaParts, horaInstant, HORA_MS } from '../utils/bogota-time.js';

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
    validadoPorId: turno.validadoPorId,
    validadoEn: turno.validadoEn,
  };
}

async function calcularTotales(turnoId, baseInicial) {
  const totalesPorMetodo = await pagoRepository.sumPorMetodoByTurno(turnoId);
  const totalRecaudado = Object.values(totalesPorMetodo).reduce((a, b) => a + b, 0);
  const efectivoEsperado = baseInicial + totalesPorMetodo.EFECTIVO;
  return { totalesPorMetodo, totalRecaudado, efectivoEsperado };
}

// Fin de la ventana automática para el día calendario (Bogotá) de
// `referencia`: 1 hora después del cierre del HorarioOperacion vigente.
// Asume que el horario no cruza medianoche (igual que el resto del dominio:
// apertura y cierre son horas de un mismo día).
function finVentanaAutomatica(horario, referencia) {
  const { year, month, day } = bogotaParts(referencia);
  const cierre = horaInstant(year, month, day, horario.cierre);
  return new Date(cierre.getTime() + HORA_MS);
}

// Cierra de forma perezosa un turno que ya venció su ventana automática: no
// hay ningún scheduler corriendo en el backend (confirmado, no hay cron ni
// timer), así que esto se llama desde los puntos donde el propio operador o
// un ADMIN ya están consultando el turno (listarTurnos, obtenerArqueo) —
// nunca desde el flujo de pagos, para no acoplar el cálculo de un cobro a
// esta resolución. La apertura NUNCA es automática/silenciosa: el operador
// la confirma explícitamente (ver abrirTurno) — devolvió a la app la
// decisión de "abrir sí o no" en vez de decidirla en segundo plano.
// Devuelve el turno ABIERTO vigente del operador tras resolver cualquier
// transición pendiente, o null si no tiene ninguno.
export async function resolverTurnoAutomatico(operadorId, ahora = new Date()) {
  const turnoAbierto = await turnoRepository.findAbiertoByOperador(operadorId);
  if (!turnoAbierto) return null;

  const horario = await horarioRepository.findVigente(ahora);
  // Sin horario de operación vigente no hay ventana que resolver.
  if (!horario) return turnoAbierto;

  // La ventana se calcula sobre el día en que el turno se abrió, no sobre
  // "hoy": un turno abierto ayer y nunca cerrado debe pasar a pendiente de
  // arqueo aunque ahora mismo estemos dentro de la ventana de hoy.
  const fin = finVentanaAutomatica(horario, turnoAbierto.apertura);
  if (ahora <= fin) return turnoAbierto;

  const { totalRecaudado, efectivoEsperado } = await calcularTotales(
    turnoAbierto.id,
    turnoAbierto.baseInicial,
  );
  await turnoRepository.marcarPendienteArqueo(turnoAbierto.id, {
    cierre: ahora,
    totalRecaudado,
    efectivoEsperado,
  });
  return null;
}

// El operador confirma explícitamente el inicio de turno (botón "Iniciar" en
// la app, apenas detecta que no tiene uno abierto) — nunca se abre solo en
// segundo plano. Si no manda baseInicial, se usa la que configuró el ADMIN
// para la apertura automática, así el operador no tiene que digitarla; si
// manda una, se respeta esa (apertura manual de siempre).
export async function abrirTurno({ baseInicial }, { operadorId }) {
  const turnoAbierto = await turnoRepository.findAbiertoByOperador(operadorId);
  if (turnoAbierto) {
    throw new ConflictError('Ya tiene un turno abierto', 'TURNO_YA_ABIERTO');
  }

  let baseInicialEfectiva = baseInicial;
  if (baseInicialEfectiva === undefined) {
    baseInicialEfectiva = await usuarioRepository.findAdminConBaseInicial();
    if (baseInicialEfectiva === null) {
      throw new UnprocessableEntityError(
        'Ningún administrador ha configurado la baseInicial para apertura automática',
        'BASE_INICIAL_NO_CONFIGURADA',
      );
    }
  }

  return turnoRepository.create({ operadorId, baseInicial: baseInicialEfectiva });
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

  const { totalesPorMetodo, totalRecaudado, efectivoEsperado } = await calcularTotales(
    id,
    turno.baseInicial,
  );
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

// Completa el arqueo de un turno que quedó CERRADO_PENDIENTE_ARQUEO (lo pasó
// ahí resolverTurnoAutomatico porque se acabó la ventana horaria y nadie
// había contado el efectivo todavía). Solo un ADMIN puede hacerlo — a
// diferencia de cerrarTurno, no hay excepción para el operador dueño, porque
// esta validación ES el control diario que pide el negocio.
export async function completarArqueo(id, { efectivoContado }, { usuarioId, rol }) {
  const turno = await turnoRepository.findById(id);
  if (!turno) {
    throw new NotFoundError(`Turno con id "${id}" no encontrado`, 'TURNO_NO_ENCONTRADO');
  }

  if (rol !== 'ADMIN') {
    throw new ForbiddenError(
      'Solo un administrador puede completar el arqueo',
      'TURNO_ARQUEO_SOLO_ADMIN',
    );
  }

  if (turno.estado !== 'CERRADO_PENDIENTE_ARQUEO') {
    throw new ConflictError('El turno no está pendiente de arqueo', 'TURNO_NO_PENDIENTE_ARQUEO');
  }

  const diferencia = efectivoContado - turno.efectivoEsperado;

  const turnoValidado = await turnoRepository.completarArqueo(id, {
    efectivoContado,
    diferencia,
    validadoPorId: usuarioId,
    validadoEn: new Date(),
  });

  const { totalesPorMetodo } = await calcularTotales(id, turnoValidado.baseInicial);
  const ticketsCerrados = await ticketRepository.countCerradosPorOperadorEnRango({
    operadorId: turnoValidado.operadorId,
    desde: turnoValidado.apertura,
    hasta: turnoValidado.cierre,
  });

  return armarArqueo(turnoValidado, { totalesPorMetodo, ticketsCerrados });
}

export async function obtenerArqueo(id, { usuarioId, rol }) {
  let turno = await turnoRepository.findById(id);
  if (!turno) {
    throw new NotFoundError(`Turno con id "${id}" no encontrado`, 'TURNO_NO_ENCONTRADO');
  }

  if (turno.operadorId !== usuarioId && rol !== 'ADMIN') {
    throw new ForbiddenError('No puede ver el arqueo del turno de otro operador', 'TURNO_AJENO');
  }

  // Consultar el arqueo es, en la práctica, el momento en que alguien vuelve
  // a fijarse en este turno: aprovecha para resolver si ya debería haber
  // pasado a CERRADO_PENDIENTE_ARQUEO.
  if (turno.estado === 'ABIERTO') {
    await resolverTurnoAutomatico(turno.operadorId);
    turno = await turnoRepository.findById(id);
  }

  const { totalesPorMetodo } = await calcularTotales(id, turno.baseInicial);
  const ticketsCerrados = await ticketRepository.countCerradosPorOperadorEnRango({
    operadorId: turno.operadorId,
    desde: turno.apertura,
    hasta: turno.cierre,
  });

  return armarArqueo(turno, { totalesPorMetodo, ticketsCerrados });
}

export async function listarTurnos(query, { usuarioId, rol }) {
  const { operadorId, estado, desde, hasta, page, perPage } = query;

  // Resuelve el turno automático del propio operador antes de listar, para
  // que "mis turnos" siempre refleje el estado real y no uno que ya venció
  // pero nadie había vuelto a consultar.
  if (rol === 'OPERADOR') {
    await resolverTurnoAutomatico(usuarioId);
  }

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
