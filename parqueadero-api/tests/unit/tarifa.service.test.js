import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { NotFoundError, UnprocessableEntityError } from '../../src/errors/index.js';
import * as tarifaRepository from '../../src/repositories/tarifa.repository.js';
import * as horarioRepository from '../../src/repositories/horario-operacion.repository.js';
import {
  listarTarifas,
  obtenerTarifaPorId,
  crearTarifa,
  cerrarTarifa,
  simularTarifa,
} from '../../src/services/tarifa.service.js';

vi.mock('../../src/repositories/tarifa.repository.js', () => ({
  findMany: vi.fn(),
  findById: vi.fn(),
  crearConAutoCierre: vi.fn(),
  cerrar: vi.fn(),
}));

vi.mock('../../src/repositories/horario-operacion.repository.js', () => ({
  findVigente: vi.fn(),
}));

function buildHorario(overrides = {}) {
  return {
    id: 'horario-id-1',
    apertura: '06:00',
    cierre: '21:00',
    vigenteDesde: new Date('2020-01-01T00:00:00.000Z'),
    vigenteHasta: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

function buildTarifa(overrides = {}) {
  return {
    id: 'tarifa-id-1',
    tipoVehiculo: 'CARRO',
    valorMinuto: 100,
    valorPlena: 20000,
    valorNocturna: 16000,
    valorMes: 180000,
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

describe('tarifa.service', () => {
  describe('listarTarifas', () => {
    it('devuelve tarifas sin filtros', async () => {
      const tarifas = [buildTarifa()];
      tarifaRepository.findMany.mockResolvedValue({ items: tarifas, total: 1 });

      const result = await listarTarifas({ page: 1, perPage: 20 });

      expect(result).toEqual({ tarifas, total: 1, page: 1, perPage: 20 });
      expect(tarifaRepository.findMany).toHaveBeenCalledWith({
        tipoVehiculo: undefined,
        vigente: undefined,
        page: 1,
        perPage: 20,
      });
    });

    it('pasa los filtros al repositorio', async () => {
      tarifaRepository.findMany.mockResolvedValue({ items: [], total: 0 });

      await listarTarifas({ tipoVehiculo: 'MOTO', vigente: true, page: 2, perPage: 10 });

      expect(tarifaRepository.findMany).toHaveBeenCalledWith({
        tipoVehiculo: 'MOTO',
        vigente: true,
        page: 2,
        perPage: 10,
      });
    });
  });

  describe('obtenerTarifaPorId', () => {
    it('devuelve la tarifa si existe', async () => {
      const tarifa = buildTarifa();
      tarifaRepository.findById.mockResolvedValue(tarifa);

      const result = await obtenerTarifaPorId(tarifa.id);

      expect(result).toBe(tarifa);
    });

    it('lanza NotFoundError si no existe', async () => {
      tarifaRepository.findById.mockResolvedValue(null);

      await expect(obtenerTarifaPorId('inexistente')).rejects.toBeInstanceOf(NotFoundError);
    });
  });

  describe('crearTarifa', () => {
    it('delega al repositorio con vigenteDesde = ahora', async () => {
      const ahora = new Date('2026-06-01T12:00:00.000Z');
      vi.useFakeTimers();
      vi.setSystemTime(ahora);

      const datos = {
        tipoVehiculo: 'CARRO',
        valorMinuto: 100,
        valorPlena: 20000,
        valorNocturna: 16000,
        valorMes: 180000,
      };
      const tarifa = buildTarifa({ vigenteDesde: ahora });
      tarifaRepository.crearConAutoCierre.mockResolvedValue(tarifa);

      const result = await crearTarifa(datos);

      expect(result).toBe(tarifa);
      expect(tarifaRepository.crearConAutoCierre).toHaveBeenCalledWith({
        ...datos,
        vigenteDesde: ahora,
      });
    });
  });

  describe('cerrarTarifa', () => {
    it('cierra la tarifa si existe', async () => {
      const tarifa = buildTarifa();
      tarifaRepository.findById.mockResolvedValue(tarifa);
      tarifaRepository.cerrar.mockResolvedValue({ ...tarifa, vigenteHasta: new Date() });

      const result = await cerrarTarifa(tarifa.id);

      expect(result.vigenteHasta).not.toBeNull();
      expect(tarifaRepository.cerrar).toHaveBeenCalledWith(tarifa.id, expect.any(Date));
    });

    it('lanza NotFoundError si no existe y no llama a cerrar', async () => {
      tarifaRepository.findById.mockResolvedValue(null);

      await expect(cerrarTarifa('inexistente')).rejects.toBeInstanceOf(NotFoundError);
      expect(tarifaRepository.cerrar).not.toHaveBeenCalled();
    });
  });

  describe('simularTarifa', () => {
    it('calcula por bloques con la horaEntrada dada y el horario vigente en ese instante', async () => {
      horarioRepository.findVigente.mockResolvedValue(buildHorario());

      const result = await simularTarifa({
        tipoVehiculo: 'CARRO',
        valorMinuto: 100,
        valorPlena: 20000,
        valorNocturna: 16000,
        duracionMinutos: 90,
        horaEntrada: new Date('2026-01-05T13:00:00.000Z'), // 8:00 AM Bogotá
      });

      expect(result.valorTotal).toBe(9000);
      expect(result.horaSalida).toEqual(new Date('2026-01-05T14:30:00.000Z'));
      expect(horarioRepository.findVigente).toHaveBeenCalledWith(
        new Date('2026-01-05T13:00:00.000Z'),
      );
      expect(tarifaRepository.findMany).not.toHaveBeenCalled();
      expect(tarifaRepository.crearConAutoCierre).not.toHaveBeenCalled();
    });

    it('usa la hora actual como horaEntrada por defecto', async () => {
      const ahora = new Date('2026-01-05T13:00:00.000Z');
      vi.useFakeTimers();
      vi.setSystemTime(ahora);
      horarioRepository.findVigente.mockResolvedValue(buildHorario());

      const result = await simularTarifa({
        tipoVehiculo: 'CARRO',
        valorMinuto: 100,
        valorPlena: 20000,
        valorNocturna: 16000,
        duracionMinutos: 90,
      });

      expect(result.horaEntrada).toEqual(ahora);
      expect(result.horaSalida).toEqual(new Date('2026-01-05T14:30:00.000Z'));
    });

    it('vehículo OTRO: no calcula, indica que el valor lo digita el operador', async () => {
      horarioRepository.findVigente.mockResolvedValue(buildHorario());

      const result = await simularTarifa({
        tipoVehiculo: 'OTRO',
        valorMinuto: 0,
        valorPlena: 0,
        valorNocturna: 0,
        duracionMinutos: 90,
        horaEntrada: new Date('2026-01-05T13:00:00.000Z'),
      });

      expect(result.valorTotal).toBeNull();
      expect(result.desglose).toEqual([
        { tipo: 'MANUAL', valor: null, motivo: expect.any(String) },
      ]);
    });

    it('lanza UnprocessableEntityError HORARIO_NO_VIGENTE si no hay horario vigente', async () => {
      horarioRepository.findVigente.mockResolvedValue(null);
      expect.assertions(2);

      try {
        await simularTarifa({
          tipoVehiculo: 'CARRO',
          valorMinuto: 100,
          valorPlena: 20000,
          valorNocturna: 16000,
          duracionMinutos: 90,
          horaEntrada: new Date('2026-01-05T13:00:00.000Z'),
        });
      } catch (err) {
        expect(err).toBeInstanceOf(UnprocessableEntityError);
        expect(err.code).toBe('HORARIO_NO_VIGENTE');
      }
    });
  });
});
