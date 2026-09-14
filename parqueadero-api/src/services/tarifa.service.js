import * as tarifaRepository from '../repositories/tarifa.repository.js';
import * as horarioRepository from '../repositories/horario-operacion.repository.js';
import * as ticketRepository from '../repositories/ticket.repository.js';
import { previsualizarTarifa } from './tarifa-calculo.service.js';
import { NotFoundError, ConflictError, UnprocessableEntityError } from '../errors/index.js';

export async function listarTarifas(query) {
  const { tipoVehiculo, vigente, page, perPage } = query;
  const { items, total } = await tarifaRepository.findMany({
    tipoVehiculo,
    vigente,
    page,
    perPage,
  });
  return { tarifas: items, total, page, perPage };
}

export async function obtenerTarifaPorId(id) {
  const tarifa = await tarifaRepository.findById(id);
  if (!tarifa) {
    throw new NotFoundError(`Tarifa con id "${id}" no encontrada`, 'TARIFA_NO_ENCONTRADA');
  }
  return tarifa;
}

// Crear una tarifa de un tipoVehiculo cierra automáticamente (en la misma
// transacción, dentro del repositorio) la vigente anterior del mismo tipo.
// Nunca hay que editar una tarifa vigente que ya tenga tickets asociados:
// la única forma de "cambiar" precios es crear una vigencia nueva.
export async function crearTarifa(data) {
  return tarifaRepository.crearConAutoCierre({ ...data, vigenteDesde: new Date() });
}

export async function cerrarTarifa(id) {
  await obtenerTarifaPorId(id);
  return tarifaRepository.cerrar(id, new Date());
}

export async function actualizarTarifa(id, data) {
  await obtenerTarifaPorId(id);

  if (await ticketRepository.existsByTarifaId(id)) {
    throw new ConflictError(
      'No se puede editar una tarifa que ya tiene tickets asociados',
      'TARIFA_CON_TICKETS_ASOCIADOS',
    );
  }

  return tarifaRepository.update(id, data);
}

// Sirve para probar una tarifa hipotética antes de guardarla. horaEntrada es
// el instante de referencia para los cortes de apertura/cierre que usa el
// cálculo por bloques; no es una función pura de la duración sola. Ya no
// existe un horario fijo por defecto, así que consulta el HorarioOperacion
// vigente en ese instante (por eso deja de ser una función pura/síncrona).
export async function simularTarifa({
  tipoVehiculo,
  valorMinuto,
  valorPlena,
  valorNocturna,
  duracionMinutos,
  horaEntrada,
}) {
  const entrada = horaEntrada ?? new Date();
  const salida = new Date(entrada.getTime() + duracionMinutos * 60_000);

  const horario = await horarioRepository.findVigente(entrada);
  if (!horario) {
    throw new UnprocessableEntityError(
      'No hay un horario de operación vigente',
      'HORARIO_NO_VIGENTE',
    );
  }

  const { valorTotal, desglose } = previsualizarTarifa({
    horaEntrada: entrada,
    horaSalida: salida,
    tarifa: { tipoVehiculo, valorMinuto, valorPlena, valorNocturna },
    horario: { apertura: horario.apertura, cierre: horario.cierre },
  });

  return { valorTotal, desglose, horaEntrada: entrada, horaSalida: salida };
}
