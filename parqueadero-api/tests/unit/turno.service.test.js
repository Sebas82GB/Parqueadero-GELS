import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  NotFoundError,
  ConflictError,
  ForbiddenError,
  UnprocessableEntityError,
} from '../../src/errors/index.js';
import * as turnoRepository from '../../src/repositories/turno.repository.js';
import * as pagoRepository from '../../src/repositories/pago.repository.js';
import * as ticketRepository from '../../src/repositories/ticket.repository.js';
import * as horarioRepository from '../../src/repositories/horario-operacion.repository.js';
import * as usuarioRepository from '../../src/repositories/usuario.repository.js';
import {
  abrirTurno,
  cerrarTurno,
  completarArqueo,
  obtenerArqueo,
  listarTurnos,
  resolverTurnoAutomatico,
} from '../../src/services/turno.service.js';

vi.mock('../../src/repositories/turno.repository.js', () => ({
  findById: vi.fn(),
  findAbiertoByOperador: vi.fn(),
  create: vi.fn(),
  cerrar: vi.fn(),
  marcarPendienteArqueo: vi.fn(),
  completarArqueo: vi.fn(),
  findMany: vi.fn(),
}));

vi.mock('../../src/repositories/pago.repository.js', () => ({
  sumPorMetodoByTurno: vi.fn(),
}));

vi.mock('../../src/repositories/ticket.repository.js', () => ({
  countCerradosPorOperadorEnRango: vi.fn(),
}));

vi.mock('../../src/repositories/horario-operacion.repository.js', () => ({
  findVigente: vi.fn(),
}));

vi.mock('../../src/repositories/usuario.repository.js', () => ({
  findAdminConBaseInicial: vi.fn(),
}));

const HORARIO = { apertura: '08:00', cierre: '21:30' };

function buildTurno(overrides = {}) {
  return {
    id: 'turno-id-1',
    operadorId: 'operador-id-1',
    apertura: new Date(),
    cierre: null,
    baseInicial: 50000,
    totalRecaudado: null,
    efectivoContado: null,
    efectivoEsperado: null,
    diferencia: null,
    estado: 'ABIERTO',
    ...overrides,
  };
}

beforeEach(() => {
  vi.resetAllMocks();
});

describe('turno.service', () => {
  describe('abrirTurno', () => {
    it('abre el turno si el operador no tiene uno abierto', async () => {
      turnoRepository.findAbiertoByOperador.mockResolvedValue(null);
      const turno = buildTurno();
      turnoRepository.create.mockResolvedValue(turno);

      const result = await abrirTurno({ baseInicial: 50000 }, { operadorId: 'operador-id-1' });

      expect(result).toBe(turno);
      expect(turnoRepository.create).toHaveBeenCalledWith({
        operadorId: 'operador-id-1',
        baseInicial: 50000,
      });
    });

    it('lanza ConflictError TURNO_YA_ABIERTO si ya tiene uno abierto', async () => {
      turnoRepository.findAbiertoByOperador.mockResolvedValue(buildTurno());

      const error = await abrirTurno({ baseInicial: 50000 }, { operadorId: 'operador-id-1' }).catch(
        (e) => e,
      );

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('TURNO_YA_ABIERTO');
      expect(turnoRepository.create).not.toHaveBeenCalled();
    });

    it('sin baseInicial: usa la configurada por un ADMIN para la apertura automática', async () => {
      turnoRepository.findAbiertoByOperador.mockResolvedValue(null);
      usuarioRepository.findAdminConBaseInicial.mockResolvedValue(30000);
      const turno = buildTurno({ baseInicial: 30000 });
      turnoRepository.create.mockResolvedValue(turno);

      const result = await abrirTurno({}, { operadorId: 'operador-id-1' });

      expect(result).toBe(turno);
      expect(turnoRepository.create).toHaveBeenCalledWith({
        operadorId: 'operador-id-1',
        baseInicial: 30000,
      });
    });

    it('sin baseInicial y sin ADMIN configurado: lanza UnprocessableEntityError BASE_INICIAL_NO_CONFIGURADA', async () => {
      turnoRepository.findAbiertoByOperador.mockResolvedValue(null);
      usuarioRepository.findAdminConBaseInicial.mockResolvedValue(null);

      const error = await abrirTurno({}, { operadorId: 'operador-id-1' }).catch((e) => e);

      expect(error).toBeInstanceOf(UnprocessableEntityError);
      expect(error.code).toBe('BASE_INICIAL_NO_CONFIGURADA');
      expect(turnoRepository.create).not.toHaveBeenCalled();
    });
  });

  describe('cerrarTurno', () => {
    function mockCierreExitoso(turno) {
      turnoRepository.findById.mockResolvedValue(turno);
      turnoRepository.cerrar.mockImplementation(async (id, data) => ({
        ...turno,
        ...data,
        estado: 'CERRADO',
      }));
      ticketRepository.countCerradosPorOperadorEnRango.mockResolvedValue(4);
    }

    it('cuadre exacto: efectivoContado igual al esperado, diferencia 0', async () => {
      const turno = buildTurno({ baseInicial: 50000 });
      mockCierreExitoso(turno);
      pagoRepository.sumPorMetodoByTurno.mockResolvedValue({
        EFECTIVO: 20000,
        TARJETA: 15000,
        TRANSFERENCIA: 0,
      });

      const result = await cerrarTurno(
        turno.id,
        { efectivoContado: 70000 },
        { usuarioId: turno.operadorId, rol: 'OPERADOR' },
      );

      expect(result.efectivoEsperado).toBe(70000); // baseInicial + EFECTIVO, ignora TARJETA
      expect(result.efectivoContado).toBe(70000);
      expect(result.diferencia).toBe(0);
      expect(result.totalRecaudado).toBe(35000); // suma de TODOS los métodos
      expect(result.totalesPorMetodo).toEqual({ EFECTIVO: 20000, TARJETA: 15000, TRANSFERENCIA: 0 });
      expect(result.ticketsCerrados).toBe(4);
      expect(turnoRepository.cerrar).toHaveBeenCalledWith(
        turno.id,
        expect.objectContaining({
          totalRecaudado: 35000,
          efectivoContado: 70000,
          efectivoEsperado: 70000,
          diferencia: 0,
        }),
      );
    });

    it('sobrante: efectivoContado mayor al esperado, diferencia positiva', async () => {
      const turno = buildTurno({ baseInicial: 50000 });
      mockCierreExitoso(turno);
      pagoRepository.sumPorMetodoByTurno.mockResolvedValue({
        EFECTIVO: 20000,
        TARJETA: 0,
        TRANSFERENCIA: 0,
      });

      const result = await cerrarTurno(
        turno.id,
        { efectivoContado: 75000 },
        { usuarioId: turno.operadorId, rol: 'OPERADOR' },
      );

      expect(result.efectivoEsperado).toBe(70000);
      expect(result.diferencia).toBe(5000);
    });

    it('faltante: efectivoContado menor al esperado, diferencia negativa', async () => {
      const turno = buildTurno({ baseInicial: 50000 });
      mockCierreExitoso(turno);
      pagoRepository.sumPorMetodoByTurno.mockResolvedValue({
        EFECTIVO: 20000,
        TARJETA: 0,
        TRANSFERENCIA: 0,
      });

      const result = await cerrarTurno(
        turno.id,
        { efectivoContado: 60000 },
        { usuarioId: turno.operadorId, rol: 'OPERADOR' },
      );

      expect(result.efectivoEsperado).toBe(70000);
      expect(result.diferencia).toBe(-10000);
    });

    it('sin pagos: totalRecaudado y efectivoEsperado caen al baseInicial', async () => {
      const turno = buildTurno({ baseInicial: 50000 });
      mockCierreExitoso(turno);
      pagoRepository.sumPorMetodoByTurno.mockResolvedValue({
        EFECTIVO: 0,
        TARJETA: 0,
        TRANSFERENCIA: 0,
      });

      const result = await cerrarTurno(
        turno.id,
        { efectivoContado: 50000 },
        { usuarioId: turno.operadorId, rol: 'OPERADOR' },
      );

      expect(result.totalRecaudado).toBe(0);
      expect(result.efectivoEsperado).toBe(50000);
      expect(result.diferencia).toBe(0);
    });

    it('lanza NotFoundError si el turno no existe', async () => {
      turnoRepository.findById.mockResolvedValue(null);

      await expect(
        cerrarTurno('inexistente', { efectivoContado: 0 }, { usuarioId: 'operador-id-1', rol: 'OPERADOR' }),
      ).rejects.toBeInstanceOf(NotFoundError);
    });

    it('lanza ConflictError TURNO_YA_CERRADO si ya está cerrado', async () => {
      turnoRepository.findById.mockResolvedValue(buildTurno({ estado: 'CERRADO' }));

      const error = await cerrarTurno(
        'turno-id-1',
        { efectivoContado: 0 },
        { usuarioId: 'operador-id-1', rol: 'OPERADOR' },
      ).catch((e) => e);

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('TURNO_YA_CERRADO');
    });

    it('lanza ForbiddenError TURNO_AJENO si otro operador intenta cerrarlo', async () => {
      turnoRepository.findById.mockResolvedValue(buildTurno({ operadorId: 'operador-id-1' }));

      const error = await cerrarTurno(
        'turno-id-1',
        { efectivoContado: 0 },
        { usuarioId: 'operador-id-2', rol: 'OPERADOR' },
      ).catch((e) => e);

      expect(error).toBeInstanceOf(ForbiddenError);
      expect(error.code).toBe('TURNO_AJENO');
      expect(turnoRepository.cerrar).not.toHaveBeenCalled();
    });

    it('permite que un ADMIN cierre el turno de otro operador', async () => {
      const turno = buildTurno({ operadorId: 'operador-id-1', baseInicial: 50000 });
      mockCierreExitoso(turno);
      pagoRepository.sumPorMetodoByTurno.mockResolvedValue({
        EFECTIVO: 0,
        TARJETA: 0,
        TRANSFERENCIA: 0,
      });

      const result = await cerrarTurno(
        turno.id,
        { efectivoContado: 50000 },
        { usuarioId: 'admin-id', rol: 'ADMIN' },
      );

      expect(result.estado).toBe('CERRADO');
    });
  });

  describe('obtenerArqueo', () => {
    it('turno ABIERTO: arqueo parcial, efectivoContado y diferencia en null, sin tope superior de fecha', async () => {
      const turno = buildTurno({ baseInicial: 50000, cierre: null, estado: 'ABIERTO' });
      turnoRepository.findById.mockResolvedValue(turno);
      pagoRepository.sumPorMetodoByTurno.mockResolvedValue({
        EFECTIVO: 20000,
        TARJETA: 10000,
        TRANSFERENCIA: 0,
      });
      ticketRepository.countCerradosPorOperadorEnRango.mockResolvedValue(2);

      const result = await obtenerArqueo(turno.id, { usuarioId: turno.operadorId, rol: 'OPERADOR' });

      expect(result.efectivoContado).toBeNull();
      expect(result.diferencia).toBeNull();
      expect(result.efectivoEsperado).toBe(70000);
      expect(result.totalRecaudado).toBe(30000);
      expect(result.ticketsCerrados).toBe(2);
      expect(ticketRepository.countCerradosPorOperadorEnRango).toHaveBeenCalledWith({
        operadorId: turno.operadorId,
        desde: turno.apertura,
        hasta: null,
      });
    });

    it('turno CERRADO: arqueo final con los valores ya persistidos', async () => {
      const turno = buildTurno({
        baseInicial: 50000,
        estado: 'CERRADO',
        cierre: new Date(),
        efectivoContado: 68000,
        efectivoEsperado: 70000,
        diferencia: -2000,
      });
      turnoRepository.findById.mockResolvedValue(turno);
      pagoRepository.sumPorMetodoByTurno.mockResolvedValue({
        EFECTIVO: 20000,
        TARJETA: 10000,
        TRANSFERENCIA: 0,
      });
      ticketRepository.countCerradosPorOperadorEnRango.mockResolvedValue(2);

      const result = await obtenerArqueo(turno.id, { usuarioId: turno.operadorId, rol: 'OPERADOR' });

      expect(result.efectivoContado).toBe(68000);
      expect(result.diferencia).toBe(-2000);
    });

    it('lanza NotFoundError si el turno no existe', async () => {
      turnoRepository.findById.mockResolvedValue(null);

      await expect(
        obtenerArqueo('inexistente', { usuarioId: 'operador-id-1', rol: 'OPERADOR' }),
      ).rejects.toBeInstanceOf(NotFoundError);
    });

    it('lanza ForbiddenError TURNO_AJENO si otro operador intenta verlo', async () => {
      turnoRepository.findById.mockResolvedValue(buildTurno({ operadorId: 'operador-id-1' }));

      const error = await obtenerArqueo('turno-id-1', {
        usuarioId: 'operador-id-2',
        rol: 'OPERADOR',
      }).catch((e) => e);

      expect(error).toBeInstanceOf(ForbiddenError);
      expect(error.code).toBe('TURNO_AJENO');
    });

    it('permite que un ADMIN vea el arqueo del turno de otro operador', async () => {
      const turno = buildTurno({ operadorId: 'operador-id-1' });
      turnoRepository.findById.mockResolvedValue(turno);
      pagoRepository.sumPorMetodoByTurno.mockResolvedValue({
        EFECTIVO: 0,
        TARJETA: 0,
        TRANSFERENCIA: 0,
      });
      ticketRepository.countCerradosPorOperadorEnRango.mockResolvedValue(0);

      const result = await obtenerArqueo(turno.id, { usuarioId: 'admin-id', rol: 'ADMIN' });

      expect(result.turnoId).toBe(turno.id);
    });
  });

  describe('listarTurnos', () => {
    it('OPERADOR: fuerza operadorId al propio usuario aunque pida otro en el filtro', async () => {
      turnoRepository.findMany.mockResolvedValue({ items: [], total: 0 });

      await listarTurnos(
        { operadorId: 'operador-ajeno', page: 1, perPage: 20 },
        { usuarioId: 'operador-id-1', rol: 'OPERADOR' },
      );

      expect(turnoRepository.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ operadorId: 'operador-id-1' }),
      );
    });

    it('ADMIN: respeta el operadorId del filtro (o su ausencia, para ver todos)', async () => {
      turnoRepository.findMany.mockResolvedValue({ items: [], total: 0 });

      await listarTurnos(
        { operadorId: undefined, page: 1, perPage: 20 },
        { usuarioId: 'admin-id', rol: 'ADMIN' },
      );

      expect(turnoRepository.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ operadorId: undefined }),
      );
    });

    it('devuelve turnos/total/page/perPage', async () => {
      const turno = buildTurno();
      turnoRepository.findMany.mockResolvedValue({ items: [turno], total: 1 });

      const result = await listarTurnos(
        { page: 1, perPage: 20 },
        { usuarioId: 'admin-id', rol: 'ADMIN' },
      );

      expect(result).toEqual({ turnos: [turno], total: 1, page: 1, perPage: 20 });
    });
  });

  describe('resolverTurnoAutomatico', () => {
    it('sin turno abierto: no hace nada y devuelve null, sin importar el horario', async () => {
      turnoRepository.findAbiertoByOperador.mockResolvedValue(null);

      const result = await resolverTurnoAutomatico('operador-id-1', new Date('2026-08-20T15:00:00.000Z'));

      expect(result).toBeNull();
      expect(turnoRepository.create).not.toHaveBeenCalled();
      expect(horarioRepository.findVigente).not.toHaveBeenCalled();
    });

    it('sin horario vigente, no hace nada: devuelve el turno abierto tal cual', async () => {
      horarioRepository.findVigente.mockResolvedValue(null);
      const turno = buildTurno();
      turnoRepository.findAbiertoByOperador.mockResolvedValue(turno);

      const result = await resolverTurnoAutomatico('operador-id-1', new Date('2026-08-20T15:00:00.000Z'));

      expect(result).toBe(turno);
      expect(turnoRepository.marcarPendienteArqueo).not.toHaveBeenCalled();
    });

    it('turno abierto dentro de la ventana: lo deja como está', async () => {
      horarioRepository.findVigente.mockResolvedValue(HORARIO);
      // apertura del turno: 2026-08-20 08:00 Bogotá = 13:00 UTC
      const turno = buildTurno({ apertura: new Date('2026-08-20T13:00:00.000Z') });
      turnoRepository.findAbiertoByOperador.mockResolvedValue(turno);

      // 2026-08-20 10:00 Bogotá = 15:00 UTC, dentro de [07:00, 22:30] Bogotá
      const result = await resolverTurnoAutomatico('operador-id-1', new Date('2026-08-20T15:00:00.000Z'));

      expect(result).toBe(turno);
      expect(turnoRepository.marcarPendienteArqueo).not.toHaveBeenCalled();
    });

    it('turno abierto con la ventana ya vencida: lo pasa a CERRADO_PENDIENTE_ARQUEO y devuelve null', async () => {
      horarioRepository.findVigente.mockResolvedValue(HORARIO);
      const turno = buildTurno({ apertura: new Date('2026-08-20T13:00:00.000Z'), baseInicial: 50000 });
      turnoRepository.findAbiertoByOperador.mockResolvedValue(turno);
      pagoRepository.sumPorMetodoByTurno.mockResolvedValue({ EFECTIVO: 20000, TARJETA: 0, TRANSFERENCIA: 0 });

      // cierre (21:30 Bogotá) + 1h = 2026-08-21T03:30:00Z; esto ya pasa de ahí.
      const ahora = new Date('2026-08-21T04:00:00.000Z');
      const result = await resolverTurnoAutomatico('operador-id-1', ahora);

      expect(result).toBeNull();
      expect(turnoRepository.marcarPendienteArqueo).toHaveBeenCalledWith(turno.id, {
        cierre: ahora,
        totalRecaudado: 20000,
        efectivoEsperado: 70000,
      });
      expect(turnoRepository.create).not.toHaveBeenCalled();
    });
  });

  describe('completarArqueo', () => {
    function buildPendiente(overrides = {}) {
      return buildTurno({
        estado: 'CERRADO_PENDIENTE_ARQUEO',
        cierre: new Date('2026-08-21T04:00:00.000Z'),
        efectivoEsperado: 70000,
        totalRecaudado: 20000,
        ...overrides,
      });
    }

    it('ADMIN completa el arqueo: calcula diferencia contra efectivoEsperado y cierra de verdad', async () => {
      const turno = buildPendiente();
      turnoRepository.findById.mockResolvedValue(turno);
      turnoRepository.completarArqueo.mockImplementation(async (id, data) => ({
        ...turno,
        ...data,
        estado: 'CERRADO',
      }));
      pagoRepository.sumPorMetodoByTurno.mockResolvedValue({ EFECTIVO: 20000, TARJETA: 0, TRANSFERENCIA: 0 });
      ticketRepository.countCerradosPorOperadorEnRango.mockResolvedValue(3);

      const result = await completarArqueo(
        turno.id,
        { efectivoContado: 68000 },
        { usuarioId: 'admin-id', rol: 'ADMIN' },
      );

      expect(turnoRepository.completarArqueo).toHaveBeenCalledWith(
        turno.id,
        expect.objectContaining({
          efectivoContado: 68000,
          diferencia: -2000,
          validadoPorId: 'admin-id',
        }),
      );
      expect(result.estado).toBe('CERRADO');
      expect(result.diferencia).toBe(-2000);
      expect(result.ticketsCerrados).toBe(3);
    });

    it('lanza NotFoundError si el turno no existe', async () => {
      turnoRepository.findById.mockResolvedValue(null);

      await expect(
        completarArqueo('inexistente', { efectivoContado: 0 }, { usuarioId: 'admin-id', rol: 'ADMIN' }),
      ).rejects.toBeInstanceOf(NotFoundError);
    });

    it('lanza ForbiddenError si quien completa no es ADMIN, aunque sea el dueño del turno', async () => {
      const turno = buildPendiente({ operadorId: 'operador-id-1' });
      turnoRepository.findById.mockResolvedValue(turno);

      const error = await completarArqueo(
        turno.id,
        { efectivoContado: 70000 },
        { usuarioId: 'operador-id-1', rol: 'OPERADOR' },
      ).catch((e) => e);

      expect(error).toBeInstanceOf(ForbiddenError);
      expect(error.code).toBe('TURNO_ARQUEO_SOLO_ADMIN');
      expect(turnoRepository.completarArqueo).not.toHaveBeenCalled();
    });

    it('lanza ConflictError TURNO_NO_PENDIENTE_ARQUEO si el turno sigue ABIERTO', async () => {
      const turno = buildTurno({ estado: 'ABIERTO' });
      turnoRepository.findById.mockResolvedValue(turno);

      const error = await completarArqueo(
        turno.id,
        { efectivoContado: 0 },
        { usuarioId: 'admin-id', rol: 'ADMIN' },
      ).catch((e) => e);

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('TURNO_NO_PENDIENTE_ARQUEO');
    });

    it('lanza ConflictError TURNO_NO_PENDIENTE_ARQUEO si el turno ya está CERRADO', async () => {
      const turno = buildTurno({ estado: 'CERRADO' });
      turnoRepository.findById.mockResolvedValue(turno);

      const error = await completarArqueo(
        turno.id,
        { efectivoContado: 0 },
        { usuarioId: 'admin-id', rol: 'ADMIN' },
      ).catch((e) => e);

      expect(error).toBeInstanceOf(ConflictError);
      expect(error.code).toBe('TURNO_NO_PENDIENTE_ARQUEO');
    });
  });
});
