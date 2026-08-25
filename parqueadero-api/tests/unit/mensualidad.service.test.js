import { describe, it, expect, vi, beforeEach } from 'vitest';
import { NotFoundError, ConflictError } from '../../src/errors/index.js';
import * as mensualidadRepository from '../../src/repositories/mensualidad.repository.js';
import * as vehiculoRepository from '../../src/repositories/vehiculo.repository.js';
import * as celdaRepository from '../../src/repositories/celda.repository.js';
import * as turnoRepository from '../../src/repositories/turno.repository.js';
import {
  listarMensualidades,
  obtenerMensualidadPorId,
  crearMensualidad,
  actualizarMensualidad,
  pagarMensualidad,
  cancelarMensualidad,
} from '../../src/services/mensualidad.service.js';

vi.mock('../../src/repositories/mensualidad.repository.js', () => ({
  findMany: vi.fn(),
  findById: vi.fn(),
  existsSolapada: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  pagarTransaccional: vi.fn(),
  cancelar: vi.fn(),
}));

vi.mock('../../src/repositories/vehiculo.repository.js', () => ({
  upsertByPlaca: vi.fn(),
}));

vi.mock('../../src/repositories/celda.repository.js', () => ({
  findById: vi.fn(),
}));

vi.mock('../../src/repositories/turno.repository.js', () => ({
  findAbiertoByOperador: vi.fn(),
}));

function buildMensualidad(overrides = {}) {
  return {
    id: 'mensualidad-id-1',
    vehiculoId: 'vehiculo-id-1',
    celdaId: null,
    fechaInicio: new Date('2020-01-01T00:00:00.000Z'),
    fechaFin: new Date('2099-01-01T00:00:00.000Z'),
    valorMensualidad: 180000,
    estadoPago: 'NO_PAGADA',
    fechaPago: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

function buildVehiculo(overrides = {}) {
  return {
    id: 'vehiculo-id-1',
    placa: 'ABC123',
    tipo: 'CARRO',
    propietarioNombre: null,
    propietarioTelefono: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

beforeEach(() => {
  vi.resetAllMocks();
});

describe('mensualidad.service', () => {
  describe('listarMensualidades', () => {
    it('pasa los filtros al repositorio', async () => {
      mensualidadRepository.findMany.mockResolvedValue({ items: [], total: 0 });

      await listarMensualidades({
        estadoPago: 'PAGADA',
        placa: 'ABC123',
        vigencia: 'VIGENTE',
        diasPorVencer: 7,
        page: 1,
        perPage: 20,
      });

      expect(mensualidadRepository.findMany).toHaveBeenCalledWith({
        estadoPago: 'PAGADA',
        placa: 'ABC123',
        vigencia: 'VIGENTE',
        diasPorVencer: 7,
        page: 1,
        perPage: 20,
      });
    });
  });

  describe('obtenerMensualidadPorId', () => {
    it('devuelve la mensualidad si existe', async () => {
      const mensualidad = buildMensualidad();
      mensualidadRepository.findById.mockResolvedValue(mensualidad);

      const result = await obtenerMensualidadPorId(mensualidad.id);

      expect(result).toBe(mensualidad);
    });

    it('lanza NotFoundError si no existe', async () => {
      mensualidadRepository.findById.mockResolvedValue(null);

      await expect(obtenerMensualidadPorId('inexistente')).rejects.toBeInstanceOf(NotFoundError);
    });
  });

  describe('crearMensualidad', () => {
    const datos = {
      placa: 'ABC123',
      tipoVehiculo: 'CARRO',
      fechaInicio: new Date('2026-01-01T00:00:00.000Z'),
      fechaFin: new Date('2026-02-01T00:00:00.000Z'),
      valorMensualidad: 180000,
    };

    it('crea o reutiliza el vehículo por placa y crea la mensualidad', async () => {
      const vehiculo = buildVehiculo();
      vehiculoRepository.upsertByPlaca.mockResolvedValue(vehiculo);
      mensualidadRepository.existsSolapada.mockResolvedValue(false);
      const mensualidad = buildMensualidad({ vehiculoId: vehiculo.id });
      mensualidadRepository.create.mockResolvedValue(mensualidad);

      const result = await crearMensualidad(datos);

      expect(result).toBe(mensualidad);
      expect(vehiculoRepository.upsertByPlaca).toHaveBeenCalledWith({
        placa: datos.placa,
        tipo: datos.tipoVehiculo,
        propietarioNombre: undefined,
        propietarioTelefono: undefined,
      });
      expect(mensualidadRepository.create).toHaveBeenCalledWith({
        vehiculoId: vehiculo.id,
        celdaId: undefined,
        fechaInicio: datos.fechaInicio,
        fechaFin: datos.fechaFin,
        valorMensualidad: datos.valorMensualidad,
      });
    });

    it('lanza ConflictError MENSUALIDAD_SOLAPADA si las fechas se solapan', async () => {
      vehiculoRepository.upsertByPlaca.mockResolvedValue(buildVehiculo());
      mensualidadRepository.existsSolapada.mockResolvedValue(true);

      const error = await crearMensualidad(datos).catch((e) => e);

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('MENSUALIDAD_SOLAPADA');
      expect(mensualidadRepository.create).not.toHaveBeenCalled();
    });

    it('lanza NotFoundError CELDA_NO_ENCONTRADA si la celda no existe', async () => {
      vehiculoRepository.upsertByPlaca.mockResolvedValue(buildVehiculo());
      celdaRepository.findById.mockResolvedValue(null);

      const error = await crearMensualidad({ ...datos, celdaId: 'celda-inexistente' }).catch(
        (e) => e,
      );

      expect(error).toBeInstanceOf(NotFoundError);
      expect(error.code).toBe('CELDA_NO_ENCONTRADA');
      expect(mensualidadRepository.existsSolapada).not.toHaveBeenCalled();
    });
  });

  describe('actualizarMensualidad', () => {
    it('actualiza sin chequear solapamiento si el patch no trae fechas', async () => {
      const mensualidad = buildMensualidad();
      mensualidadRepository.findById.mockResolvedValue(mensualidad);
      mensualidadRepository.update.mockResolvedValue({ ...mensualidad, valorMensualidad: 200000 });

      const result = await actualizarMensualidad(mensualidad.id, { valorMensualidad: 200000 });

      expect(result.valorMensualidad).toBe(200000);
      expect(mensualidadRepository.existsSolapada).not.toHaveBeenCalled();
    });

    it('chequea solapamiento excluyéndose a sí misma al mover fechas', async () => {
      const mensualidad = buildMensualidad();
      mensualidadRepository.findById.mockResolvedValue(mensualidad);
      mensualidadRepository.existsSolapada.mockResolvedValue(false);
      mensualidadRepository.update.mockResolvedValue(mensualidad);

      const nuevaFechaFin = new Date('2099-06-01T00:00:00.000Z');
      await actualizarMensualidad(mensualidad.id, { fechaFin: nuevaFechaFin });

      expect(mensualidadRepository.existsSolapada).toHaveBeenCalledWith({
        vehiculoId: mensualidad.vehiculoId,
        fechaInicio: mensualidad.fechaInicio,
        fechaFin: nuevaFechaFin,
        excludeId: mensualidad.id,
      });
    });

    it('lanza ConflictError MENSUALIDAD_SOLAPADA si las nuevas fechas chocan', async () => {
      const mensualidad = buildMensualidad();
      mensualidadRepository.findById.mockResolvedValue(mensualidad);
      mensualidadRepository.existsSolapada.mockResolvedValue(true);

      const error = await actualizarMensualidad(mensualidad.id, {
        fechaFin: new Date('2099-06-01T00:00:00.000Z'),
      }).catch((e) => e);

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('MENSUALIDAD_SOLAPADA');
      expect(mensualidadRepository.update).not.toHaveBeenCalled();
    });

    it('lanza ConflictError MENSUALIDAD_CANCELADA si está cancelada', async () => {
      mensualidadRepository.findById.mockResolvedValue(buildMensualidad({ estadoPago: 'CANCELADA' }));

      const error = await actualizarMensualidad('id', { valorMensualidad: 200000 }).catch(
        (e) => e,
      );

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('MENSUALIDAD_CANCELADA');
      expect(mensualidadRepository.update).not.toHaveBeenCalled();
    });
  });

  describe('pagarMensualidad', () => {
    it('paga con el turno abierto de quien llama', async () => {
      const mensualidad = buildMensualidad({ estadoPago: 'NO_PAGADA', valorMensualidad: 180000 });
      mensualidadRepository.findById.mockResolvedValue(mensualidad);
      turnoRepository.findAbiertoByOperador.mockResolvedValue({ id: 'turno-id-1' });
      const pagada = { ...mensualidad, estadoPago: 'PAGADA' };
      mensualidadRepository.pagarTransaccional.mockResolvedValue(pagada);

      const result = await pagarMensualidad(
        mensualidad.id,
        { metodo: 'EFECTIVO' },
        { usuarioId: 'usuario-id-1' },
      );

      expect(result).toBe(pagada);
      expect(mensualidadRepository.pagarTransaccional).toHaveBeenCalledWith({
        mensualidadId: mensualidad.id,
        fechaPago: expect.any(Date),
        pago: { monto: 180000, metodo: 'EFECTIVO', turnoId: 'turno-id-1' },
      });
    });

    it('lanza ConflictError MENSUALIDAD_CANCELADA', async () => {
      mensualidadRepository.findById.mockResolvedValue(buildMensualidad({ estadoPago: 'CANCELADA' }));

      const error = await pagarMensualidad('id', { metodo: 'EFECTIVO' }, { usuarioId: 'u1' }).catch(
        (e) => e,
      );

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('MENSUALIDAD_CANCELADA');
    });

    it('lanza ConflictError MENSUALIDAD_YA_PAGADA', async () => {
      mensualidadRepository.findById.mockResolvedValue(buildMensualidad({ estadoPago: 'PAGADA' }));

      const error = await pagarMensualidad('id', { metodo: 'EFECTIVO' }, { usuarioId: 'u1' }).catch(
        (e) => e,
      );

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('MENSUALIDAD_YA_PAGADA');
    });

    it('lanza ConflictError OPERADOR_SIN_TURNO_ABIERTO si no tiene turno', async () => {
      mensualidadRepository.findById.mockResolvedValue(buildMensualidad({ estadoPago: 'NO_PAGADA' }));
      turnoRepository.findAbiertoByOperador.mockResolvedValue(null);

      const error = await pagarMensualidad('id', { metodo: 'EFECTIVO' }, { usuarioId: 'u1' }).catch(
        (e) => e,
      );

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('OPERADOR_SIN_TURNO_ABIERTO');
      expect(mensualidadRepository.pagarTransaccional).not.toHaveBeenCalled();
    });
  });

  describe('cancelarMensualidad', () => {
    it('cancela la mensualidad si existe', async () => {
      const mensualidad = buildMensualidad();
      mensualidadRepository.findById.mockResolvedValue(mensualidad);
      mensualidadRepository.cancelar.mockResolvedValue({ ...mensualidad, estadoPago: 'CANCELADA' });

      const result = await cancelarMensualidad(mensualidad.id);

      expect(result.estadoPago).toBe('CANCELADA');
    });

    it('lanza NotFoundError si no existe y no llama a cancelar', async () => {
      mensualidadRepository.findById.mockResolvedValue(null);

      await expect(cancelarMensualidad('inexistente')).rejects.toBeInstanceOf(NotFoundError);
      expect(mensualidadRepository.cancelar).not.toHaveBeenCalled();
    });
  });
});
