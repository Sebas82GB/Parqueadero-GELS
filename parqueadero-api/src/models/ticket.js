import { Vehiculo } from './vehiculo.js';
import { Celda } from './celda.js';
import { Tarifa } from './tarifa.js';
import { HorarioOperacion } from './horario-operacion.js';
import { Pago } from './pago.js';
import { Usuario } from './usuario.js';

export class Ticket {
  constructor({
    id,
    codigo,
    vehiculoId,
    celdaId,
    horaEntrada,
    horaSalida,
    tarifaId,
    horarioId,
    valorTotal,
    desglose,
    estado,
    operadorEntradaId,
    operadorSalidaId,
    motivoAnulacion,
    anuladoPorId,
    anuladoEn,
    entregadoPorId,
    entregadoEn,
    reciboConsecutivo,
    createdAt,
    updatedAt,
    vehiculo,
    celda,
    tarifa,
    horario,
    pago,
    operadorSalida,
  }) {
    this.id = id;
    this.codigo = codigo;
    this.vehiculoId = vehiculoId;
    this.celdaId = celdaId;
    this.horaEntrada = horaEntrada;
    this.horaSalida = horaSalida;
    this.tarifaId = tarifaId;
    this.horarioId = horarioId;
    this.valorTotal = valorTotal;
    this.desglose = desglose;
    this.estado = estado;
    this.operadorEntradaId = operadorEntradaId;
    this.operadorSalidaId = operadorSalidaId;
    this.motivoAnulacion = motivoAnulacion;
    this.anuladoPorId = anuladoPorId;
    this.anuladoEn = anuladoEn;
    this.entregadoPorId = entregadoPorId;
    this.entregadoEn = entregadoEn;
    this.reciboConsecutivo = reciboConsecutivo;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.vehiculo = vehiculo;
    this.celda = celda;
    this.tarifa = tarifa;
    this.horario = horario;
    this.pago = pago;
    this.operadorSalida = operadorSalida;
  }

  static toDomain(record) {
    return new Ticket({
      id: record.id,
      codigo: record.codigo,
      vehiculoId: record.vehiculoId,
      celdaId: record.celdaId,
      horaEntrada: record.horaEntrada,
      horaSalida: record.horaSalida,
      tarifaId: record.tarifaId,
      horarioId: record.horarioId,
      valorTotal: record.valorTotal,
      desglose: record.desglose,
      estado: record.estado,
      operadorEntradaId: record.operadorEntradaId,
      operadorSalidaId: record.operadorSalidaId,
      motivoAnulacion: record.motivoAnulacion,
      anuladoPorId: record.anuladoPorId,
      anuladoEn: record.anuladoEn,
      entregadoPorId: record.entregadoPorId,
      entregadoEn: record.entregadoEn,
      reciboConsecutivo: record.reciboConsecutivo,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      vehiculo: record.vehiculo ? Vehiculo.toDomain(record.vehiculo) : undefined,
      celda: record.celda ? Celda.toDomain(record.celda) : undefined,
      tarifa: record.tarifa ? Tarifa.toDomain(record.tarifa) : undefined,
      horario: record.horario ? HorarioOperacion.toDomain(record.horario) : undefined,
      pago: record.pago ? Pago.toDomain(record.pago) : undefined,
      // Nunca pasar el record crudo de Prisma: Usuario.toDomain es lo que
      // garantiza que passwordHash no llegue a la respuesta.
      operadorSalida: record.operadorSalida ? Usuario.toDomain(record.operadorSalida) : undefined,
    });
  }

  static toPersistence({
    codigo,
    vehiculoId,
    celdaId,
    horaEntrada,
    horaSalida,
    tarifaId,
    horarioId,
    valorTotal,
    desglose,
    estado,
    operadorEntradaId,
    operadorSalidaId,
    motivoAnulacion,
    anuladoPorId,
    anuladoEn,
    entregadoPorId,
    entregadoEn,
  } = {}) {
    const data = {};
    if (codigo !== undefined) data.codigo = codigo;
    if (vehiculoId !== undefined) data.vehiculoId = vehiculoId;
    if (celdaId !== undefined) data.celdaId = celdaId;
    if (horaEntrada !== undefined) data.horaEntrada = horaEntrada;
    if (horaSalida !== undefined) data.horaSalida = horaSalida;
    if (tarifaId !== undefined) data.tarifaId = tarifaId;
    if (horarioId !== undefined) data.horarioId = horarioId;
    if (valorTotal !== undefined) data.valorTotal = valorTotal;
    if (desglose !== undefined) data.desglose = desglose;
    if (estado !== undefined) data.estado = estado;
    if (operadorEntradaId !== undefined) data.operadorEntradaId = operadorEntradaId;
    if (operadorSalidaId !== undefined) data.operadorSalidaId = operadorSalidaId;
    if (motivoAnulacion !== undefined) data.motivoAnulacion = motivoAnulacion;
    if (anuladoPorId !== undefined) data.anuladoPorId = anuladoPorId;
    if (anuladoEn !== undefined) data.anuladoEn = anuladoEn;
    if (entregadoPorId !== undefined) data.entregadoPorId = entregadoPorId;
    if (entregadoEn !== undefined) data.entregadoEn = entregadoEn;
    return data;
  }
}
