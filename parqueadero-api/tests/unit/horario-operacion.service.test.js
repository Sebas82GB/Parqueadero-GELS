import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { NotFoundError } from '../../src/errors/index.js';
import * as horarioRepository from '../../src/repositories/horario-operacion.repository.js';
import {
  listarHorarios,
  obtenerHorarioPorId,
  crearHorario,
  cerrarHorario,
} from '../../src/services/horario-operacion.service.js';

vi.mock('../../src/repositories/horario-operacion.repository.js', () => ({
  findMany: vi.fn(),
  findById: vi.fn(),
  crearConAutoCierre: vi.fn(),
  cerrar: vi.fn(),
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
});
