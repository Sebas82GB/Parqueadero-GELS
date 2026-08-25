import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { NotFoundError, ConflictError, UnprocessableEntityError } from '../../src/errors/index.js';
import * as ticketRepository from '../../src/repositories/ticket.repository.js';
import * as vehiculoRepository from '../../src/repositories/vehiculo.repository.js';
import * as celdaRepository from '../../src/repositories/celda.repository.js';
import * as tarifaRepository from '../../src/repositories/tarifa.repository.js';
import * as horarioRepository from '../../src/repositories/horario-operacion.repository.js';
import * as mensualidadRepository from '../../src/repositories/mensualidad.repository.js';
import * as turnoRepository from '../../src/repositories/turno.repository.js';
import {
  listarTickets,
  obtenerTicketPorId,
  previsualizarCobro,
  registrarEntrada,
  registrarSalida,
  anularTicket,
  entregarTicket,
} from '../../src/services/ticket.service.js';

vi.mock('../../src/repositories/ticket.repository.js', () => ({
  findMany: vi.fn(),
  findById: vi.fn(),
  findByIdConDetalle: vi.fn(),
  findAbiertoByVehiculo: vi.fn(),
  crearEntradaTransaccional: vi.fn(),
  registrarSalidaTransaccional: vi.fn(),
  anularTransaccional: vi.fn(),
  marcarEntregado: vi.fn(),
}));
vi.mock('../../src/repositories/vehiculo.repository.js', () => ({
  upsertByPlaca: vi.fn(),
}));
vi.mock('../../src/repositories/celda.repository.js', () => ({
  findById: vi.fn(),
}));
vi.mock('../../src/repositories/tarifa.repository.js', () => ({
  findVigenteByTipo: vi.fn(),
}));
vi.mock('../../src/repositories/horario-operacion.repository.js', () => ({
  findVigente: vi.fn(),
}));
vi.mock('../../src/repositories/mensualidad.repository.js', () => ({
  findVigenteByVehiculo: vi.fn(),
  findVigenteByCelda: vi.fn(),
}));
vi.mock('../../src/repositories/turno.repository.js', () => ({
  findAbiertoByOperador: vi.fn(),
}));

const TARIFA_CARRO = {
  id: 'tarifa-carro-id',
  tipoVehiculo: 'CARRO',
  valorMinuto: 100,
  valorPlena: 20000,
  valorNocturna: 16000,
};

const TARIFA_OTRO = { id: 'tarifa-otro-id', tipoVehiculo: 'OTRO' };

const HORARIO = { id: 'horario-id-1', apertura: '06:00', cierre: '21:00' };

function buildCelda(overrides = {}) {
  return {
    id: 'celda-id-1',
    codigo: 'A-01',
    zona: 'Zona A',
    tipoPermitido: 'CARRO',
    estado: 'LIBRE',
    ...overrides,
  };
}

function buildVehiculo(overrides = {}) {
  return { id: 'vehiculo-id-1', placa: 'ABC123', tipo: 'CARRO', ...overrides };
}

function buildTicket(overrides = {}) {
  return {
    id: 'ticket-id-1',
    codigo: 'T-1',
    vehiculoId: 'vehiculo-id-1',
    celdaId: 'celda-id-1',
    horaEntrada: new Date('2026-01-05T13:00:00.000Z'), // 8:00 AM Bogotá
    tarifaId: TARIFA_CARRO.id,
    horarioId: HORARIO.id,
    estado: 'ABIERTO',
    tarifa: TARIFA_CARRO,
    horario: HORARIO,
    vehiculo: buildVehiculo(),
    ...overrides,
  };
}

beforeEach(() => {
  vi.resetAllMocks();
  mensualidadRepository.findVigenteByCelda.mockResolvedValue(null);
});

afterEach(() => {
  vi.useRealTimers();
});

describe('ticket.service', () => {
  describe('listarTickets', () => {
    it('pasa los filtros al repositorio y arma la forma de respuesta', async () => {
      ticketRepository.findMany.mockResolvedValue({ items: [buildTicket()], total: 1 });

      const result = await listarTickets({ estado: 'ABIERTO', page: 1, perPage: 20 });

      expect(result.total).toBe(1);
      expect(result.tickets).toHaveLength(1);
      expect(ticketRepository.findMany).toHaveBeenCalledWith({
        estado: 'ABIERTO',
        vehiculoId: undefined,
        celdaId: undefined,
        placa: undefined,
        desde: undefined,
        hasta: undefined,
        page: 1,
        perPage: 20,
      });
    });

    it('devuelve una lista vacía si no hay resultados', async () => {
      ticketRepository.findMany.mockResolvedValue({ items: [], total: 0 });

      const result = await listarTickets({ page: 1, perPage: 20 });

      expect(result).toEqual({ tickets: [], total: 0, page: 1, perPage: 20 });
    });

    it('reenvía placa y rango de fechas al repositorio', async () => {
      ticketRepository.findMany.mockResolvedValue({ items: [], total: 0 });
      const desde = new Date('2026-01-01T00:00:00.000Z');
      const hasta = new Date('2026-01-31T23:59:59.000Z');

      await listarTickets({ placa: 'ABC123', desde, hasta, page: 1, perPage: 20 });

      expect(ticketRepository.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ placa: 'ABC123', desde, hasta }),
      );
    });
  });

  describe('obtenerTicketPorId', () => {
    it('devuelve el ticket con detalle si existe', async () => {
      const ticket = buildTicket();
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);

      const result = await obtenerTicketPorId(ticket.id);

      expect(result).toEqual({ ...ticket, recibo: null });
    });

    it('lanza NotFoundError si no existe', async () => {
      ticketRepository.findByIdConDetalle.mockResolvedValue(null);

      await expect(obtenerTicketPorId('inexistente')).rejects.toBeInstanceOf(NotFoundError);
    });

    it('recibo es null si el ticket sigue ABIERTO', async () => {
      const ticket = buildTicket();
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);

      const result = await obtenerTicketPorId(ticket.id);

      expect(result.recibo).toBeNull();
    });

    it('recibo viene poblado si el ticket ya tiene salida registrada', async () => {
      const ticket = buildTicket({
        estado: 'PAGADO',
        horaSalida: new Date('2026-01-05T14:30:00.000Z'),
        celda: buildCelda(),
        valorTotal: 9000,
        desglose: [{ tipo: 'MANUAL', valor: 9000 }],
        pago: { metodo: 'EFECTIVO' },
        operadorSalida: { nombre: 'Carlos Pérez' },
        reciboConsecutivo: 3,
      });
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);

      const result = await obtenerTicketPorId(ticket.id);

      expect(result.recibo).not.toBeNull();
      expect(result.recibo.consecutivo).toBe(3);
      expect(result.recibo.operador).toBe('Carlos Pérez');
    });
  });

  describe('previsualizarCobro', () => {
    it('calcula por bloques sin tocar ningún método de escritura', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z')); // 9:30 AM Bogotá

      const ticket = buildTicket();
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);
      mensualidadRepository.findVigenteByVehiculo.mockResolvedValue(null);

      const result = await previsualizarCobro(ticket.id);

      expect(result.valorTotal).toBe(9000);
      expect(result.horaEntrada).toEqual(ticket.horaEntrada);
      expect(result.horaSalida).toEqual(new Date('2026-01-05T14:30:00.000Z'));
      expect(ticketRepository.registrarSalidaTransaccional).not.toHaveBeenCalled();
      expect(ticketRepository.crearEntradaTransaccional).not.toHaveBeenCalled();
      expect(ticketRepository.anularTransaccional).not.toHaveBeenCalled();
      expect(ticketRepository.marcarEntregado).not.toHaveBeenCalled();
      expect(turnoRepository.findAbiertoByOperador).not.toHaveBeenCalled();
    });

    it('con mensualidad vigente devuelve $0 con desglose MENSUALIDAD', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z'));

      const ticket = buildTicket();
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);
      mensualidadRepository.findVigenteByVehiculo.mockResolvedValue({
        fechaInicio: new Date('2026-01-01T00:00:00.000Z'),
        fechaFin: new Date('2026-01-31T00:00:00.000Z'),
        estadoPago: 'PAGADA',
      });

      const result = await previsualizarCobro(ticket.id);

      expect(result.valorTotal).toBe(0);
      expect(result.desglose).toEqual([{ tipo: 'MENSUALIDAD', valor: 0 }]);
    });

    it('mensualidad reservada para otra celda no exime: la vista previa muestra el cobro real', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z'));

      const ticket = buildTicket({ celdaId: 'celda-id-1' });
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);
      mensualidadRepository.findVigenteByVehiculo.mockResolvedValue({
        celdaId: 'celda-id-2',
        fechaInicio: new Date('2026-01-01T00:00:00.000Z'),
        fechaFin: new Date('2026-01-31T00:00:00.000Z'),
        estadoPago: 'PAGADA',
      });

      const result = await previsualizarCobro(ticket.id);

      expect(result.valorTotal).toBe(9000);
      expect(result.desglose.some((b) => b.tipoCobro === 'MENSUALIDAD')).toBe(false);
    });

    it('vehículo OTRO sin mensualidad: valorTotal null, indica que lo digita el operador', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z'));

      const ticket = buildTicket({
        tarifa: TARIFA_OTRO,
        vehiculo: buildVehiculo({ tipo: 'OTRO' }),
      });
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);
      mensualidadRepository.findVigenteByVehiculo.mockResolvedValue(null);

      const result = await previsualizarCobro(ticket.id);

      expect(result.valorTotal).toBeNull();
      expect(result.desglose).toEqual([
        { tipo: 'MANUAL', valor: null, motivo: expect.any(String) },
      ]);
    });

    it('lanza NotFoundError si el ticket no existe', async () => {
      ticketRepository.findByIdConDetalle.mockResolvedValue(null);

      await expect(previsualizarCobro('inexistente')).rejects.toBeInstanceOf(NotFoundError);
    });

    it.each(['PAGADO', 'ENTREGADO', 'ANULADO'])(
      'lanza ConflictError TICKET_NO_ABIERTO si el ticket está %s',
      async (estado) => {
        ticketRepository.findByIdConDetalle.mockResolvedValue(buildTicket({ estado }));

        const error = await previsualizarCobro('ticket-id-1').catch((e) => e);

        expect(error).toBeInstanceOf(ConflictError);
        expect(error.code).toBe('TICKET_NO_ABIERTO');
        expect(mensualidadRepository.findVigenteByVehiculo).not.toHaveBeenCalled();
      },
    );
  });

  describe('registrarEntrada', () => {
    const payload = { placa: 'abc123', tipoVehiculo: 'CARRO', celdaId: 'celda-id-1' };
    const contexto = { operadorId: 'operador-id-1' };

    it('crea el ticket cuando todo es válido', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda());
      vehiculoRepository.upsertByPlaca.mockResolvedValue(buildVehiculo());
      ticketRepository.findAbiertoByVehiculo.mockResolvedValue(null);
      tarifaRepository.findVigenteByTipo.mockResolvedValue(TARIFA_CARRO);
      horarioRepository.findVigente.mockResolvedValue(HORARIO);
      const ticketCreado = buildTicket();
      ticketRepository.crearEntradaTransaccional.mockResolvedValue(ticketCreado);

      const result = await registrarEntrada(payload, contexto);

      expect(result).toBe(ticketCreado);
      expect(ticketRepository.crearEntradaTransaccional).toHaveBeenCalledWith(
        expect.objectContaining({
          vehiculoId: 'vehiculo-id-1',
          celdaId: 'celda-id-1',
          tarifaId: TARIFA_CARRO.id,
          horarioId: HORARIO.id,
          operadorEntradaId: 'operador-id-1',
        }),
      );
    });

    it('usa el tipo ya guardado del vehículo existente, ignorando el payload', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda({ tipoPermitido: 'MOTO' }));
      vehiculoRepository.upsertByPlaca.mockResolvedValue(buildVehiculo({ tipo: 'MOTO' }));
      ticketRepository.findAbiertoByVehiculo.mockResolvedValue(null);
      tarifaRepository.findVigenteByTipo.mockResolvedValue({
        ...TARIFA_CARRO,
        tipoVehiculo: 'MOTO',
      });
      horarioRepository.findVigente.mockResolvedValue(HORARIO);
      ticketRepository.crearEntradaTransaccional.mockResolvedValue(buildTicket());

      await registrarEntrada({ ...payload, tipoVehiculo: 'CARRO' }, contexto);

      expect(tarifaRepository.findVigenteByTipo).toHaveBeenCalledWith('MOTO', expect.any(Date));
    });

    it('lanza NotFoundError CELDA_NO_ENCONTRADA si la celda no existe', async () => {
      celdaRepository.findById.mockResolvedValue(null);

      const error = await registrarEntrada(payload, contexto).catch((e) => e);

      expect(error).toBeInstanceOf(NotFoundError);
      expect(error.code).toBe('CELDA_NO_ENCONTRADA');
      expect(ticketRepository.crearEntradaTransaccional).not.toHaveBeenCalled();
    });

    it('lanza ConflictError CELDA_OCUPADA si la celda está ocupada', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda({ estado: 'OCUPADA' }));

      const error = await registrarEntrada(payload, contexto).catch((e) => e);

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('CELDA_OCUPADA');
      expect(ticketRepository.crearEntradaTransaccional).not.toHaveBeenCalled();
    });

    it('lanza ConflictError CELDA_EN_MANTENIMIENTO si la celda está en mantenimiento', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda({ estado: 'MANTENIMIENTO' }));

      const error = await registrarEntrada(payload, contexto).catch((e) => e);

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('CELDA_EN_MANTENIMIENTO');
      expect(ticketRepository.crearEntradaTransaccional).not.toHaveBeenCalled();
    });

    it('lanza UnprocessableEntityError CELDA_TIPO_INCOMPATIBLE si el tipo no coincide', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda({ tipoPermitido: 'MOTO' }));
      vehiculoRepository.upsertByPlaca.mockResolvedValue(buildVehiculo({ tipo: 'CARRO' }));

      const error = await registrarEntrada(payload, contexto).catch((e) => e);

      expect(error).toBeInstanceOf(UnprocessableEntityError);
      expect(error.code).toBe('CELDA_TIPO_INCOMPATIBLE');
      expect(ticketRepository.crearEntradaTransaccional).not.toHaveBeenCalled();
    });

    it('lanza ConflictError CELDA_RESERVADA_MENSUALIDAD si la celda tiene mensualidad vigente de otro vehículo', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda());
      vehiculoRepository.upsertByPlaca.mockResolvedValue(buildVehiculo({ id: 'vehiculo-id-1' }));
      mensualidadRepository.findVigenteByCelda.mockResolvedValue({
        id: 'mensualidad-id-1',
        vehiculoId: 'vehiculo-id-2',
      });

      const error = await registrarEntrada(payload, contexto).catch((e) => e);

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('CELDA_RESERVADA_MENSUALIDAD');
      expect(ticketRepository.crearEntradaTransaccional).not.toHaveBeenCalled();
    });

    it('permite la entrada si la celda tiene mensualidad vigente del mismo vehículo', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda());
      vehiculoRepository.upsertByPlaca.mockResolvedValue(buildVehiculo({ id: 'vehiculo-id-1' }));
      mensualidadRepository.findVigenteByCelda.mockResolvedValue({
        id: 'mensualidad-id-1',
        vehiculoId: 'vehiculo-id-1',
      });
      ticketRepository.findAbiertoByVehiculo.mockResolvedValue(null);
      tarifaRepository.findVigenteByTipo.mockResolvedValue(TARIFA_CARRO);
      horarioRepository.findVigente.mockResolvedValue(HORARIO);
      const ticketCreado = buildTicket();
      ticketRepository.crearEntradaTransaccional.mockResolvedValue(ticketCreado);

      const result = await registrarEntrada(payload, contexto);

      expect(result).toBe(ticketCreado);
    });

    it('lanza ConflictError VEHICULO_CON_TICKET_ABIERTO si ya tiene un ticket abierto', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda());
      vehiculoRepository.upsertByPlaca.mockResolvedValue(buildVehiculo());
      ticketRepository.findAbiertoByVehiculo.mockResolvedValue(buildTicket());

      const error = await registrarEntrada(payload, contexto).catch((e) => e);

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('VEHICULO_CON_TICKET_ABIERTO');
      expect(ticketRepository.crearEntradaTransaccional).not.toHaveBeenCalled();
    });

    it('lanza UnprocessableEntityError TARIFA_NO_VIGENTE si no hay tarifa vigente', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda());
      vehiculoRepository.upsertByPlaca.mockResolvedValue(buildVehiculo());
      ticketRepository.findAbiertoByVehiculo.mockResolvedValue(null);
      tarifaRepository.findVigenteByTipo.mockResolvedValue(null);

      const error = await registrarEntrada(payload, contexto).catch((e) => e);

      expect(error).toBeInstanceOf(UnprocessableEntityError);
      expect(error.code).toBe('TARIFA_NO_VIGENTE');
      expect(ticketRepository.crearEntradaTransaccional).not.toHaveBeenCalled();
    });

    it('lanza UnprocessableEntityError HORARIO_NO_VIGENTE si no hay horario vigente', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda());
      vehiculoRepository.upsertByPlaca.mockResolvedValue(buildVehiculo());
      ticketRepository.findAbiertoByVehiculo.mockResolvedValue(null);
      tarifaRepository.findVigenteByTipo.mockResolvedValue(TARIFA_CARRO);
      horarioRepository.findVigente.mockResolvedValue(null);

      const error = await registrarEntrada(payload, contexto).catch((e) => e);

      expect(error).toBeInstanceOf(UnprocessableEntityError);
      expect(error.code).toBe('HORARIO_NO_VIGENTE');
      expect(ticketRepository.crearEntradaTransaccional).not.toHaveBeenCalled();
    });
  });

  describe('registrarSalida', () => {
    const contexto = { operadorId: 'operador-id-1' };

    it('cobra por estadía y crea el pago con el turno abierto del operador', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z')); // 9:30 AM Bogotá

      const ticket = buildTicket();
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);
      mensualidadRepository.findVigenteByVehiculo.mockResolvedValue(null);
      turnoRepository.findAbiertoByOperador.mockResolvedValue({ id: 'turno-id-1' });
      const ticketCerrado = buildTicket({
        estado: 'PAGADO',
        horaSalida: new Date('2026-01-05T14:30:00.000Z'),
        celda: buildCelda(),
        valorTotal: 9000,
        desglose: [{ dia: 1, bloqueNumero: 1, tipoCobro: 'PARCIAL', valor: 9000 }],
        pago: { metodo: 'EFECTIVO' },
        operadorSalida: { nombre: 'Carlos Pérez' },
        reciboConsecutivo: 7,
      });
      ticketRepository.registrarSalidaTransaccional.mockResolvedValue(ticketCerrado);

      const result = await registrarSalida(ticket.id, { metodo: 'EFECTIVO' }, contexto);

      expect(ticketRepository.registrarSalidaTransaccional).toHaveBeenCalledWith(
        expect.objectContaining({
          ticketId: ticket.id,
          valorTotal: 9000,
          pago: { monto: 9000, metodo: 'EFECTIVO', turnoId: 'turno-id-1' },
        }),
      );
      expect(result.recibo).toEqual({
        consecutivo: 7,
        fechaEmision: ticketCerrado.horaSalida,
        establecimiento: expect.any(Object),
        placa: ticket.vehiculo.placa,
        tipoVehiculo: ticket.vehiculo.tipo,
        celda: ticketCerrado.celda.codigo,
        horaEntrada: ticketCerrado.horaEntrada,
        horaSalida: ticketCerrado.horaSalida,
        tiempoTotal: '1h 30min',
        desglose: ticketCerrado.desglose,
        total: 9000,
        metodoPago: 'EFECTIVO',
        operador: 'Carlos Pérez',
      });
    });

    it('con mensualidad vigente cierra en 0 sin crear pago ni consultar el turno', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z'));

      const ticket = buildTicket();
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);
      mensualidadRepository.findVigenteByVehiculo.mockResolvedValue({
        fechaInicio: new Date('2026-01-01T00:00:00.000Z'),
        fechaFin: new Date('2026-01-31T00:00:00.000Z'),
        estadoPago: 'PAGADA',
      });
      ticketRepository.registrarSalidaTransaccional.mockResolvedValue(
        buildTicket({ estado: 'PAGADO', valorTotal: 0 }),
      );

      await registrarSalida(ticket.id, {}, contexto);

      expect(ticketRepository.registrarSalidaTransaccional).toHaveBeenCalledWith(
        expect.objectContaining({ valorTotal: 0, pago: null }),
      );
      expect(turnoRepository.findAbiertoByOperador).not.toHaveBeenCalled();
    });

    it('mensualidad reservada para otra celda no exime: cobra el valor real y sí exige turno', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z')); // 9:30 AM Bogotá

      const ticket = buildTicket({ celdaId: 'celda-id-1' });
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);
      mensualidadRepository.findVigenteByVehiculo.mockResolvedValue({
        celdaId: 'celda-id-2',
        fechaInicio: new Date('2026-01-01T00:00:00.000Z'),
        fechaFin: new Date('2026-01-31T00:00:00.000Z'),
        estadoPago: 'PAGADA',
      });
      turnoRepository.findAbiertoByOperador.mockResolvedValue({ id: 'turno-id-1' });
      ticketRepository.registrarSalidaTransaccional.mockResolvedValue(
        buildTicket({ estado: 'PAGADO', valorTotal: 9000 }),
      );

      await registrarSalida(ticket.id, { metodo: 'EFECTIVO' }, contexto);

      expect(ticketRepository.registrarSalidaTransaccional).toHaveBeenCalledWith(
        expect.objectContaining({ valorTotal: 9000 }),
      );
      expect(turnoRepository.findAbiertoByOperador).toHaveBeenCalled();
    });

    it('vehículo OTRO usa valorManual sin calcular bloques', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z'));

      const ticket = buildTicket({
        tarifa: TARIFA_OTRO,
        vehiculo: buildVehiculo({ tipo: 'OTRO' }),
      });
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);
      mensualidadRepository.findVigenteByVehiculo.mockResolvedValue(null);
      turnoRepository.findAbiertoByOperador.mockResolvedValue({ id: 'turno-id-1' });
      ticketRepository.registrarSalidaTransaccional.mockResolvedValue(
        buildTicket({ estado: 'PAGADO', valorTotal: 15000 }),
      );

      await registrarSalida(ticket.id, { metodo: 'EFECTIVO', valorManual: 15000 }, contexto);

      expect(ticketRepository.registrarSalidaTransaccional).toHaveBeenCalledWith(
        expect.objectContaining({ valorTotal: 15000 }),
      );
    });

    it('lanza NotFoundError si el ticket no existe', async () => {
      ticketRepository.findByIdConDetalle.mockResolvedValue(null);

      await expect(registrarSalida('inexistente', {}, contexto)).rejects.toBeInstanceOf(
        NotFoundError,
      );
    });

    it.each(['PAGADO', 'ENTREGADO', 'ANULADO'])(
      'lanza ConflictError TICKET_NO_ABIERTO si el ticket está %s',
      async (estado) => {
        ticketRepository.findByIdConDetalle.mockResolvedValue(buildTicket({ estado }));

        const error = await registrarSalida('ticket-id-1', {}, contexto).catch((e) => e);

        expect(error).toBeInstanceOf(ConflictError);
        expect(error.code).toBe('TICKET_NO_ABIERTO');
        expect(ticketRepository.registrarSalidaTransaccional).not.toHaveBeenCalled();
      },
    );

    it('lanza UnprocessableEntityError VALOR_MANUAL_REQUERIDO para OTRO sin valorManual', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z'));

      const ticket = buildTicket({
        tarifa: TARIFA_OTRO,
        vehiculo: buildVehiculo({ tipo: 'OTRO' }),
      });
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);
      mensualidadRepository.findVigenteByVehiculo.mockResolvedValue(null);

      const error = await registrarSalida(ticket.id, {}, contexto).catch((e) => e);

      expect(error).toBeInstanceOf(UnprocessableEntityError);
      expect(error.code).toBe('VALOR_MANUAL_REQUERIDO');
      expect(ticketRepository.registrarSalidaTransaccional).not.toHaveBeenCalled();
    });

    it('lanza UnprocessableEntityError METODO_PAGO_REQUERIDO si hay cobro y no viene método', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z'));

      const ticket = buildTicket();
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);
      mensualidadRepository.findVigenteByVehiculo.mockResolvedValue(null);

      const error = await registrarSalida(ticket.id, {}, contexto).catch((e) => e);

      expect(error).toBeInstanceOf(UnprocessableEntityError);
      expect(error.code).toBe('METODO_PAGO_REQUERIDO');
      expect(turnoRepository.findAbiertoByOperador).not.toHaveBeenCalled();
    });

    it('lanza ConflictError OPERADOR_SIN_TURNO_ABIERTO si hay cobro y no tiene turno', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z'));

      const ticket = buildTicket();
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);
      mensualidadRepository.findVigenteByVehiculo.mockResolvedValue(null);
      turnoRepository.findAbiertoByOperador.mockResolvedValue(null);

      const error = await registrarSalida(ticket.id, { metodo: 'EFECTIVO' }, contexto).catch(
        (e) => e,
      );

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('OPERADOR_SIN_TURNO_ABIERTO');
      expect(ticketRepository.registrarSalidaTransaccional).not.toHaveBeenCalled();
    });

    it('con valorTotal 0 por OTRO valorManual:0 no exige método ni turno', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z'));

      const ticket = buildTicket({
        tarifa: TARIFA_OTRO,
        vehiculo: buildVehiculo({ tipo: 'OTRO' }),
      });
      ticketRepository.findByIdConDetalle.mockResolvedValue(ticket);
      mensualidadRepository.findVigenteByVehiculo.mockResolvedValue(null);
      ticketRepository.registrarSalidaTransaccional.mockResolvedValue(
        buildTicket({ estado: 'PAGADO', valorTotal: 0 }),
      );

      await registrarSalida(ticket.id, { valorManual: 0 }, contexto);

      expect(turnoRepository.findAbiertoByOperador).not.toHaveBeenCalled();
      expect(ticketRepository.registrarSalidaTransaccional).toHaveBeenCalledWith(
        expect.objectContaining({ valorTotal: 0, pago: null }),
      );
    });
  });

  describe('anularTicket', () => {
    const contexto = { usuarioId: 'usuario-id-1' };

    it('anula el ticket abierto y libera la celda', async () => {
      const ticket = buildTicket();
      ticketRepository.findById.mockResolvedValue(ticket);
      const anulado = buildTicket({ estado: 'ANULADO' });
      ticketRepository.anularTransaccional.mockResolvedValue(anulado);

      const result = await anularTicket(ticket.id, { motivo: 'Placa equivocada' }, contexto);

      expect(result).toBe(anulado);
      expect(ticketRepository.anularTransaccional).toHaveBeenCalledWith(
        expect.objectContaining({
          ticketId: ticket.id,
          celdaId: ticket.celdaId,
          motivo: 'Placa equivocada',
          anuladoPorId: 'usuario-id-1',
        }),
      );
    });

    it('lanza NotFoundError si el ticket no existe', async () => {
      ticketRepository.findById.mockResolvedValue(null);

      await expect(anularTicket('inexistente', { motivo: 'x' }, contexto)).rejects.toBeInstanceOf(
        NotFoundError,
      );
    });

    it.each(['PAGADO', 'ENTREGADO', 'ANULADO'])(
      'lanza ConflictError TICKET_NO_ABIERTO si el ticket está %s',
      async (estado) => {
        ticketRepository.findById.mockResolvedValue(buildTicket({ estado }));

        const error = await anularTicket('ticket-id-1', { motivo: 'x' }, contexto).catch((e) => e);

        expect(error).toBeInstanceOf(ConflictError);
        expect(error.code).toBe('TICKET_NO_ABIERTO');
        expect(ticketRepository.anularTransaccional).not.toHaveBeenCalled();
      },
    );
  });

  describe('entregarTicket', () => {
    const contexto = { usuarioId: 'usuario-id-1' };

    it('marca como entregado un ticket pagado', async () => {
      ticketRepository.findById.mockResolvedValue(buildTicket({ estado: 'PAGADO' }));
      const entregado = buildTicket({ estado: 'ENTREGADO' });
      ticketRepository.marcarEntregado.mockResolvedValue(entregado);

      const result = await entregarTicket('ticket-id-1', contexto);

      expect(result).toBe(entregado);
      expect(ticketRepository.marcarEntregado).toHaveBeenCalledWith(
        'ticket-id-1',
        expect.objectContaining({ entregadoPorId: 'usuario-id-1' }),
      );
    });

    it('lanza NotFoundError si el ticket no existe', async () => {
      ticketRepository.findById.mockResolvedValue(null);

      await expect(entregarTicket('inexistente', contexto)).rejects.toBeInstanceOf(NotFoundError);
    });

    it.each(['ABIERTO', 'ANULADO', 'ENTREGADO'])(
      'lanza ConflictError TICKET_NO_PAGADO si el ticket está %s',
      async (estado) => {
        ticketRepository.findById.mockResolvedValue(buildTicket({ estado }));

        const error = await entregarTicket('ticket-id-1', contexto).catch((e) => e);

        expect(error).toBeInstanceOf(ConflictError);
        expect(error.code).toBe('TICKET_NO_PAGADO');
        expect(ticketRepository.marcarEntregado).not.toHaveBeenCalled();
      },
    );
  });
});
