import { describe, it, expect, vi, beforeEach } from 'vitest';
import { NotFoundError, ConflictError } from '../../src/errors/index.js';
import * as celdaRepository from '../../src/repositories/celda.repository.js';
import {
  listarCeldas,
  obtenerCeldaPorId,
  crearCelda,
  actualizarCelda,
  marcarMantenimiento,
  volverALibre,
} from '../../src/services/celda.service.js';

vi.mock('../../src/repositories/celda.repository.js', () => ({
  findMany: vi.fn(),
  findById: vi.fn(),
  findByCodigo: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
}));

function buildCelda(overrides = {}) {
  return {
    id: 'celda-id-1',
    codigo: 'A-01',
    zona: 'Zona A',
    tipoPermitido: 'CARRO',
    estado: 'LIBRE',
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

beforeEach(() => {
  vi.resetAllMocks();
});

describe('celda.service', () => {
  describe('listarCeldas', () => {
    it('devuelve celdas sin filtros', async () => {
      const celdas = [buildCelda()];
      celdaRepository.findMany.mockResolvedValue({ items: celdas, total: 1 });

      const result = await listarCeldas({ page: 1, perPage: 20 });

      expect(result).toEqual({ celdas, total: 1, page: 1, perPage: 20 });
      expect(celdaRepository.findMany).toHaveBeenCalledWith({
        zona: undefined,
        estado: undefined,
        tipoPermitido: undefined,
        page: 1,
        perPage: 20,
      });
    });

    it('pasa los filtros al repositorio', async () => {
      celdaRepository.findMany.mockResolvedValue({ items: [], total: 0 });

      await listarCeldas({
        zona: 'Zona A',
        estado: 'LIBRE',
        tipoPermitido: 'CARRO',
        page: 2,
        perPage: 10,
      });

      expect(celdaRepository.findMany).toHaveBeenCalledWith({
        zona: 'Zona A',
        estado: 'LIBRE',
        tipoPermitido: 'CARRO',
        page: 2,
        perPage: 10,
      });
    });

    it('devuelve una lista vacía si no hay resultados', async () => {
      celdaRepository.findMany.mockResolvedValue({ items: [], total: 0 });

      const result = await listarCeldas({ page: 1, perPage: 20 });

      expect(result).toEqual({ celdas: [], total: 0, page: 1, perPage: 20 });
    });
  });

  describe('obtenerCeldaPorId', () => {
    it('devuelve la celda si existe', async () => {
      const celda = buildCelda();
      celdaRepository.findById.mockResolvedValue(celda);

      const result = await obtenerCeldaPorId(celda.id);

      expect(result).toBe(celda);
    });

    it('lanza NotFoundError si no existe', async () => {
      celdaRepository.findById.mockResolvedValue(null);

      await expect(obtenerCeldaPorId('inexistente')).rejects.toBeInstanceOf(NotFoundError);
    });
  });

  describe('crearCelda', () => {
    it('crea la celda si el código no existe', async () => {
      celdaRepository.findByCodigo.mockResolvedValue(null);
      const celda = buildCelda();
      celdaRepository.create.mockResolvedValue(celda);

      const result = await crearCelda({ codigo: 'A-01', zona: 'Zona A', tipoPermitido: 'CARRO' });

      expect(result).toBe(celda);
      expect(celdaRepository.create).toHaveBeenCalledWith({
        codigo: 'A-01',
        zona: 'Zona A',
        tipoPermitido: 'CARRO',
      });
    });

    it('lanza ConflictError si el código ya existe y no llama a create', async () => {
      celdaRepository.findByCodigo.mockResolvedValue(buildCelda());

      await expect(
        crearCelda({ codigo: 'A-01', zona: 'Zona A', tipoPermitido: 'CARRO' }),
      ).rejects.toBeInstanceOf(ConflictError);
      expect(celdaRepository.create).not.toHaveBeenCalled();
    });
  });

  describe('actualizarCelda', () => {
    it('actualiza sin consultar findByCodigo si el patch no trae codigo', async () => {
      const celda = buildCelda();
      celdaRepository.findById.mockResolvedValue(celda);
      celdaRepository.update.mockResolvedValue({ ...celda, zona: 'Zona B' });

      const result = await actualizarCelda(celda.id, { zona: 'Zona B' });

      expect(result.zona).toBe('Zona B');
      expect(celdaRepository.findByCodigo).not.toHaveBeenCalled();
    });

    it('permite reenviar el mismo código sin conflicto', async () => {
      const celda = buildCelda();
      celdaRepository.findById.mockResolvedValue(celda);
      celdaRepository.findByCodigo.mockResolvedValue(celda);
      celdaRepository.update.mockResolvedValue(celda);

      const result = await actualizarCelda(celda.id, { codigo: celda.codigo });

      expect(result).toBe(celda);
    });

    it('actualiza el código a uno libre', async () => {
      const celda = buildCelda();
      celdaRepository.findById.mockResolvedValue(celda);
      celdaRepository.findByCodigo.mockResolvedValue(null);
      celdaRepository.update.mockResolvedValue({ ...celda, codigo: 'B-01' });

      const result = await actualizarCelda(celda.id, { codigo: 'B-01' });

      expect(result.codigo).toBe('B-01');
    });

    it('lanza NotFoundError si la celda no existe', async () => {
      celdaRepository.findById.mockResolvedValue(null);

      await expect(actualizarCelda('inexistente', { zona: 'Zona B' })).rejects.toBeInstanceOf(
        NotFoundError,
      );
    });

    it('lanza ConflictError si el código pertenece a otra celda', async () => {
      const celda = buildCelda();
      const otra = buildCelda({ id: 'otra-id', codigo: 'B-01' });
      celdaRepository.findById.mockResolvedValue(celda);
      celdaRepository.findByCodigo.mockResolvedValue(otra);

      await expect(actualizarCelda(celda.id, { codigo: 'B-01' })).rejects.toBeInstanceOf(
        ConflictError,
      );
    });
  });

  describe('marcarMantenimiento', () => {
    it('pasa de LIBRE a MANTENIMIENTO', async () => {
      const celda = buildCelda({ estado: 'LIBRE' });
      celdaRepository.findById.mockResolvedValue(celda);
      celdaRepository.update.mockResolvedValue({ ...celda, estado: 'MANTENIMIENTO' });

      const result = await marcarMantenimiento(celda.id);

      expect(result.estado).toBe('MANTENIMIENTO');
      expect(celdaRepository.update).toHaveBeenCalledWith(celda.id, { estado: 'MANTENIMIENTO' });
    });

    it('lanza NotFoundError si la celda no existe', async () => {
      celdaRepository.findById.mockResolvedValue(null);

      await expect(marcarMantenimiento('inexistente')).rejects.toBeInstanceOf(NotFoundError);
    });

    it('lanza ConflictError CELDA_OCUPADA si está OCUPADA', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda({ estado: 'OCUPADA' }));

      const error = await marcarMantenimiento('id').catch((e) => e);

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('CELDA_OCUPADA');
    });

    it('lanza ConflictError CELDA_ESTADO_INVALIDO si ya está en MANTENIMIENTO', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda({ estado: 'MANTENIMIENTO' }));

      const error = await marcarMantenimiento('id').catch((e) => e);

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('CELDA_ESTADO_INVALIDO');
    });
  });

  describe('volverALibre', () => {
    it('pasa de MANTENIMIENTO a LIBRE', async () => {
      const celda = buildCelda({ estado: 'MANTENIMIENTO' });
      celdaRepository.findById.mockResolvedValue(celda);
      celdaRepository.update.mockResolvedValue({ ...celda, estado: 'LIBRE' });

      const result = await volverALibre(celda.id);

      expect(result.estado).toBe('LIBRE');
      expect(celdaRepository.update).toHaveBeenCalledWith(celda.id, { estado: 'LIBRE' });
    });

    it('lanza NotFoundError si la celda no existe', async () => {
      celdaRepository.findById.mockResolvedValue(null);

      await expect(volverALibre('inexistente')).rejects.toBeInstanceOf(NotFoundError);
    });

    it('lanza ConflictError CELDA_OCUPADA si está OCUPADA', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda({ estado: 'OCUPADA' }));

      const error = await volverALibre('id').catch((e) => e);

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('CELDA_OCUPADA');
    });

    it('lanza ConflictError CELDA_ESTADO_INVALIDO si ya está LIBRE', async () => {
      celdaRepository.findById.mockResolvedValue(buildCelda({ estado: 'LIBRE' }));

      const error = await volverALibre('id').catch((e) => e);

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('CELDA_ESTADO_INVALIDO');
    });
  });
});
