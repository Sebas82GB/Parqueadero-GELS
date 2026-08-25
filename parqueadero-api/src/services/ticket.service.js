import * as ticketRepository from '../repositories/ticket.repository.js';
import * as vehiculoRepository from '../repositories/vehiculo.repository.js';
import * as celdaRepository from '../repositories/celda.repository.js';
import * as tarifaRepository from '../repositories/tarifa.repository.js';
import * as horarioRepository from '../repositories/horario-operacion.repository.js';
import * as mensualidadRepository from '../repositories/mensualidad.repository.js';
import * as turnoRepository from '../repositories/turno.repository.js';
import { calcularTarifa, previsualizarTarifa } from './tarifa-calculo.service.js';
import { construirRecibo } from './recibo.service.js';
import { generarCodigoTicket } from '../utils/codigo.util.js';
import { NotFoundError, ConflictError, UnprocessableEntityError } from '../errors/index.js';

export async function listarTickets(query) {
  const { estado, vehiculoId, celdaId, placa, desde, hasta, page, perPage } = query;
  const { items, total } = await ticketRepository.findMany({
    estado,
    vehiculoId,
    celdaId,
    placa,
    desde,
    hasta,
    page,
    perPage,
  });
  return { tickets: items, total, page, perPage };
}

export async function obtenerTicketPorId(id) {
  const ticket = await ticketRepository.findByIdConDetalle(id);
  if (!ticket) {
    throw new NotFoundError(`Ticket con id "${id}" no encontrado`, 'TICKET_NO_ENCONTRADO');
  }
  return { ...ticket, recibo: construirRecibo(ticket) };
}

export async function registrarEntrada(
  { placa, tipoVehiculo, propietarioNombre, propietarioTelefono, celdaId },
  { operadorId },
) {
  const celda = await celdaRepository.findById(celdaId);
  if (!celda) {
    throw new NotFoundError(`Celda con id "${celdaId}" no encontrada`, 'CELDA_NO_ENCONTRADA');
  }
  if (celda.estado === 'OCUPADA') {
    throw new ConflictError(`La celda ${celda.codigo} ya está ocupada`, 'CELDA_OCUPADA');
  }
  if (celda.estado === 'MANTENIMIENTO') {
    throw new ConflictError(
      `La celda ${celda.codigo} está en mantenimiento`,
      'CELDA_EN_MANTENIMIENTO',
    );
  }

  const horaEntrada = new Date();

  const vehiculo = await vehiculoRepository.upsertByPlaca({
    placa,
    tipo: tipoVehiculo,
    propietarioNombre,
    propietarioTelefono,
  });

  if (celda.tipoPermitido !== vehiculo.tipo) {
    throw new UnprocessableEntityError(
      `La celda ${celda.codigo} no admite vehículos tipo ${vehiculo.tipo}`,
      'CELDA_TIPO_INCOMPATIBLE',
    );
  }

  const mensualidadCelda = await mensualidadRepository.findVigenteByCelda(celdaId, horaEntrada);
  if (mensualidadCelda && mensualidadCelda.vehiculoId !== vehiculo.id) {
    throw new ConflictError(
      `La celda ${celda.codigo} está reservada por mensualidad para otro vehículo`,
      'CELDA_RESERVADA_MENSUALIDAD',
    );
  }

  const ticketAbierto = await ticketRepository.findAbiertoByVehiculo(vehiculo.id);
  if (ticketAbierto) {
    throw new ConflictError(
      `El vehículo ${vehiculo.placa} ya tiene un ticket abierto`,
      'VEHICULO_CON_TICKET_ABIERTO',
    );
  }

  const tarifa = await tarifaRepository.findVigenteByTipo(vehiculo.tipo, horaEntrada);
  if (!tarifa) {
    throw new UnprocessableEntityError(
      `No hay una tarifa vigente para el tipo ${vehiculo.tipo}`,
      'TARIFA_NO_VIGENTE',
    );
  }

  const horario = await horarioRepository.findVigente(horaEntrada);
  if (!horario) {
    throw new UnprocessableEntityError(
      'No hay un horario de operación vigente',
      'HORARIO_NO_VIGENTE',
    );
  }

  return ticketRepository.crearEntradaTransaccional({
    codigo: generarCodigoTicket(),
    vehiculoId: vehiculo.id,
    celdaId,
    horaEntrada,
    tarifaId: tarifa.id,
    horarioId: horario.id,
    operadorEntradaId: operadorId,
  });
}

export async function registrarSalida(id, { metodo, valorManual }, { operadorId }) {
  const ticket = await ticketRepository.findByIdConDetalle(id);
  if (!ticket) {
    throw new NotFoundError(`Ticket con id "${id}" no encontrado`, 'TICKET_NO_ENCONTRADO');
  }
  if (ticket.estado !== 'ABIERTO') {
    throw new ConflictError('El ticket ya no está abierto', 'TICKET_NO_ABIERTO');
  }

  const horaSalida = new Date();
  const mensualidad = await mensualidadRepository.findVigenteByVehiculo(
    ticket.vehiculoId,
    ticket.horaEntrada,
  );

  if (!mensualidad && ticket.vehiculo.tipo === 'OTRO' && valorManual === undefined) {
    throw new UnprocessableEntityError(
      'Para vehículos tipo OTRO se debe indicar valorManual',
      'VALOR_MANUAL_REQUERIDO',
    );
  }

  const { valorTotal, desglose } = calcularTarifa({
    horaEntrada: ticket.horaEntrada,
    horaSalida,
    tarifa: ticket.tarifa,
    mensualidad,
    celdaId: ticket.celdaId,
    valorManual,
    horario: { apertura: ticket.horario.apertura, cierre: ticket.horario.cierre },
  });

  let pago = null;
  if (valorTotal > 0) {
    if (!metodo) {
      throw new UnprocessableEntityError(
        'Se debe indicar el método de pago',
        'METODO_PAGO_REQUERIDO',
      );
    }

    const turno = await turnoRepository.findAbiertoByOperador(operadorId);
    if (!turno) {
      throw new ConflictError('No tiene un turno abierto', 'OPERADOR_SIN_TURNO_ABIERTO');
    }

    pago = { monto: valorTotal, metodo, turnoId: turno.id };
  }

  const ticketCerrado = await ticketRepository.registrarSalidaTransaccional({
    ticketId: id,
    celdaId: ticket.celdaId,
    horaSalida,
    valorTotal,
    desglose,
    operadorSalidaId: operadorId,
    pago,
  });

  return { ...ticketCerrado, recibo: construirRecibo(ticketCerrado) };
}

export async function previsualizarCobro(id) {
  const ticket = await ticketRepository.findByIdConDetalle(id);
  if (!ticket) {
    throw new NotFoundError(`Ticket con id "${id}" no encontrado`, 'TICKET_NO_ENCONTRADO');
  }
  if (ticket.estado !== 'ABIERTO') {
    throw new ConflictError('El ticket ya no está abierto', 'TICKET_NO_ABIERTO');
  }

  const horaSalida = new Date();
  const mensualidad = await mensualidadRepository.findVigenteByVehiculo(
    ticket.vehiculoId,
    ticket.horaEntrada,
  );

  const { valorTotal, desglose } = previsualizarTarifa({
    horaEntrada: ticket.horaEntrada,
    horaSalida,
    tarifa: ticket.tarifa,
    mensualidad,
    celdaId: ticket.celdaId,
    horario: { apertura: ticket.horario.apertura, cierre: ticket.horario.cierre },
  });

  return { valorTotal, desglose, horaEntrada: ticket.horaEntrada, horaSalida };
}

export async function anularTicket(id, { motivo }, { usuarioId }) {
  const ticket = await ticketRepository.findById(id);
  if (!ticket) {
    throw new NotFoundError(`Ticket con id "${id}" no encontrado`, 'TICKET_NO_ENCONTRADO');
  }
  if (ticket.estado !== 'ABIERTO') {
    throw new ConflictError('El ticket ya no está abierto', 'TICKET_NO_ABIERTO');
  }

  return ticketRepository.anularTransaccional({
    ticketId: id,
    celdaId: ticket.celdaId,
    motivo,
    anuladoPorId: usuarioId,
    anuladoEn: new Date(),
  });
}

export async function entregarTicket(id, { usuarioId }) {
  const ticket = await ticketRepository.findById(id);
  if (!ticket) {
    throw new NotFoundError(`Ticket con id "${id}" no encontrado`, 'TICKET_NO_ENCONTRADO');
  }
  if (ticket.estado !== 'PAGADO') {
    throw new ConflictError('El ticket no está pagado', 'TICKET_NO_PAGADO');
  }

  return ticketRepository.marcarEntregado(id, {
    entregadoPorId: usuarioId,
    entregadoEn: new Date(),
  });
}
