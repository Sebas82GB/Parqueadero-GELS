import * as horarioRepository from '../repositories/horario-operacion.repository.js';
import { NotFoundError } from '../errors/index.js';

export async function listarHorarios(query) {
  const { vigente, page, perPage } = query;
  const { items, total } = await horarioRepository.findMany({ vigente, page, perPage });
  return { horarios: items, total, page, perPage };
}

export async function obtenerHorarioPorId(id) {
  const horario = await horarioRepository.findById(id);
  if (!horario) {
    throw new NotFoundError(`Horario con id "${id}" no encontrado`, 'HORARIO_NO_ENCONTRADO');
  }
  return horario;
}

// Crear un horario cierra automáticamente (en la misma transacción, dentro
// del repositorio) el vigente anterior. Nunca hay que editar un horario
// vigente que ya tenga tickets asociados: la única forma de "cambiarlo" es
// crear una vigencia nueva.
export async function crearHorario(data) {
  return horarioRepository.crearConAutoCierre({ ...data, vigenteDesde: new Date() });
}

export async function cerrarHorario(id) {
  await obtenerHorarioPorId(id);
  return horarioRepository.cerrar(id, new Date());
}
