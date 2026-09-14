import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { NotFoundError, ConflictError, UnprocessableEntityError } from '../../src/errors/index.js';
import * as horarioRepository from '../../src/repositories/horario-operacion.repository.js';
import * as ticketRepository from '../../src/repositories/ticket.repository.js';
import {
  listarHorarios,
  obtenerHorarioPorId,
  crearHorario,
  cerrarHorario,
  actualizarHorario,
} from '../../src/services/horario-operacion.service.js';

vi.mock('../../src/repositories/horario-operacion.repository.js', () => ({
  findMany: vi.fn(),
  findById: vi.fn(),
  crearConAutoCierre: vi.fn(),
  cerrar: vi.fn(),
  update: vi.fn(),
}));

vi.mock('../../src/repositories/ticket.repository.js', () => ({
  existsByHorarioId: vi.fn(),
}));

function buildHorario(overrides = {}) {
  return {
    id: 'horario-id-1',
    apertura: '08:00',
    cierre: '21:30',
    vigenteDesde: new Date('2020-01-01T00:00:00.000Z'),
    vigenteHasta: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

beforeEach(() => {
  vi.resetAllMocks();
});

afterEach(() => {
  vi.useRealTimers();
});

describe('horario-operacion.service', () => {
  describe('listarHorarios', () => {
    it('devuelve horarios sin filtros', async () => {
      const horarios = [buildHorario()];
      horarioRepository.findMany.mockResolvedValue({ items: horarios, total: 1 });

      const result = await listarHorarios({ page: 1, perPage: 20 });

      expect(result).toEqual({ horarios, total: 1, page: 1, perPage: 20 });
      expect(horarioRepository.findMany).toHaveBeenCalledWith({
        vigente: undefined,
        page: 1,
        perPage: 20,
      });
    });

    it('pasa los filtros al repositorio', async () => {
      horarioRepository.findMany.mockResolvedValue({ items: [], total: 0 });

      await listarHorarios({ vigente: true, page: 2, perPage: 10 });

      expect(horarioRepository.findMany).toHaveBeenCalledWith({
        vigente: true,
        page: 2,
        perPage: 10,
      });
    });
  });

  describe('obtenerHorarioPorId', () => {
    it('devuelve el horario si existe', async () => {
      const horario = buildHorario();
      horarioRepository.findById.mockResolvedValue(horario);

      const result = await obtenerHorarioPorId(horario.id);

      expect(result).toBe(horario);
    });

    it('lanza NotFoundError si no existe', async () => {
      horarioRepository.findById.mockResolvedValue(null);

      await expect(obtenerHorarioPorId('inexistente')).rejects.toBeInstanceOf(NotFoundError);
    });
  });

  describe('crearHorario', () => {
    it('delega al repositorio con vigenteDesde = ahora', async () => {
      const ahora = new Date('2026-06-01T12:00:00.000Z');
      vi.useFakeTimers();
      vi.setSystemTime(ahora);

      const datos = { apertura: '08:00', cierre: '21:30' };
      const horario = buildHorario({ vigenteDesde: ahora });
      horarioRepository.crearConAutoCierre.mockResolvedValue(horario);

      const result = await crearHorario(datos);

      expect(result).toBe(horario);
      expect(horarioRepository.crearConAutoCierre).toHaveBeenCalledWith({
        ...datos,
        vigenteDesde: ahora,
      });
    });
  });

  describe('cerrarHorario', () => {
    it('cierra el horario si existe', async () => {
      const horario = buildHorario();
      horarioRepository.findById.mockResolvedValue(horario);
      horarioRepository.cerrar.mockResolvedValue({ ...horario, vigenteHasta: new Date() });

      const result = await cerrarHorario(horario.id);

      expect(result.vigenteHasta).not.toBeNull();
      expect(horarioRepository.cerrar).toHaveBeenCalledWith(horario.id, expect.any(Date));
    });

    it('lanza NotFoundError si no existe y no llama a cerrar', async () => {
      horarioRepository.findById.mockResolvedValue(null);

      await expect(cerrarHorario('inexistente')).rejects.toBeInstanceOf(NotFoundError);
      expect(horarioRepository.cerrar).not.toHaveBeenCalled();
    });
  });

  describe('actualizarHorario', () => {
    it('actualiza campos parciales y llama a repository.update con lo recibido', async () => {
      const horario = buildHorario();
      horarioRepository.findById.mockResolvedValue(horario);
      ticketRepository.existsByHorarioId.mockResolvedValue(false);
      const actualizado = buildHorario({ cierre: '22:00' });
      horarioRepository.update.mockResolvedValue(actualizado);

      const result = await actualizarHorario(horario.id, { cierre: '22:00' });

      expect(result).toBe(actualizado);
      expect(horarioRepository.update).toHaveBeenCalledWith(horario.id, { cierre: '22:00' });
    });

    it('lanza NotFoundError si el id no existe', async () => {
      horarioRepository.findById.mockResolvedValue(null);

      await expect(
        actualizarHorario('inexistente', { cierre: '22:00' }),
      ).rejects.toBeInstanceOf(NotFoundError);
      expect(horarioRepository.update).not.toHaveBeenCalled();
    });

    it('lanza ConflictError HORARIO_CON_TICKETS_ASOCIADOS si tiene tickets y no llama a update', async () => {
      const horario = buildHorario();
      horarioRepository.findById.mockResolvedValue(horario);
      ticketRepository.existsByHorarioId.mockResolvedValue(true);
      expect.assertions(3);

      try {
        await actualizarHorario(horario.id, { cierre: '22:00' });
      } catch (err) {
        expect(err).toBeInstanceOf(ConflictError);
        expect(err.code).toBe('HORARIO_CON_TICKETS_ASOCIADOS');
      }
      expect(horarioRepository.update).not.toHaveBeenCalled();
    });

    it('devuelve 422 HORARIO_RANGO_INVALIDO si se manda solo apertura y queda >= al cierre actual', async () => {
      const horario = buildHorario({ apertura: '08:00', cierre: '21:30' });
      horarioRepository.findById.mockResolvedValue(horario);
      ticketRepository.existsByHorarioId.mockResolvedValue(false);
      expect.assertions(3);

      try {
        await actualizarHorario(horario.id, { apertura: '22:00' });
      } catch (err) {
        expect(err).toBeInstanceOf(UnprocessableEntityError);
        expect(err.code).toBe('HORARIO_RANGO_INVALIDO');
      }
      expect(horarioRepository.update).not.toHaveBeenCalled();
    });

    it('OK si se manda solo cierre y queda posterior a la apertura actual', async () => {
      const horario = buildHorario({ apertura: '08:00', cierre: '21:30' });
      horarioRepository.findById.mockResolvedValue(horario);
      ticketRepository.existsByHorarioId.mockResolvedValue(false);
      const actualizado = buildHorario({ apertura: '08:00', cierre: '23:00' });
      horarioRepository.update.mockResolvedValue(actualizado);

      const result = await actualizarHorario(horario.id, { cierre: '23:00' });

      expect(result).toBe(actualizado);
      expect(horarioRepository.update).toHaveBeenCalledWith(horario.id, { cierre: '23:00' });
    });
  });
});
