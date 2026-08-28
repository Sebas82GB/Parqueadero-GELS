import { describe, it, expect, beforeEach, afterAll } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { prisma } from '../../src/config/database.js';
import { signTestToken } from '../helpers/jwt.js';
import { createUsuarioInDb } from '../helpers/usuario-fixture.js';
import { createCeldaInDb } from '../helpers/celda-fixture.js';
import { createVehiculoInDb } from '../helpers/vehiculo-fixture.js';
import { createTarifaInDb } from '../helpers/tarifa-fixture.js';
import { createHorarioInDb } from '../helpers/horario-fixture.js';
import { createTurnoInDb } from '../helpers/turno-fixture.js';
import { createTicketInDb } from '../helpers/ticket-fixture.js';
import {
  resetCeldas,
  resetOperacion,
  resetRefreshTokens,
  resetTarifas,
  resetHorariosOperacion,
  resetUsuarios,
  disconnectDb,
} from '../helpers/db.js';

const app = createApp();

let admin;
let operador;
let otroOperador;
let adminToken;
let operadorToken;
let otroOperadorToken;

beforeEach(async () => {
  await resetOperacion();
  await resetRefreshTokens();
  await resetUsuarios();
  await resetCeldas();
  await resetTarifas();
  await resetHorariosOperacion();

  ({ usuario: admin } = await createUsuarioInDb({ rol: 'ADMIN' }));
  ({ usuario: operador } = await createUsuarioInDb({ rol: 'OPERADOR' }));
  ({ usuario: otroOperador } = await createUsuarioInDb({ rol: 'OPERADOR' }));
  adminToken = signTestToken({ id: admin.id, rol: 'ADMIN' });
  operadorToken = signTestToken({ id: operador.id, rol: 'OPERADOR' });
  otroOperadorToken = signTestToken({ id: otroOperador.id, rol: 'OPERADOR' });
});

afterAll(async () => {
  await disconnectDb();
});

// Crea un ticket ya cerrado (PAGADO) con su Pago asociado al turno dado, para
// alimentar el arqueo. `horaSalida` por defecto es "ahora".
async function crearTicketCerradoConPago({
  turnoId,
  operadorSalidaId,
  monto,
  metodo = 'EFECTIVO',
  horaSalida = new Date(),
  estadoPago = 'VALIDO',
}) {
  const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
  const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
  const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
  const ticket = await createTicketInDb({
    vehiculoId: vehiculo.id,
    celdaId: celda.id,
    tarifaId: tarifa.id,
    operadorEntradaId: operadorSalidaId,
    estado: 'PAGADO',
    horaSalida,
    operadorSalidaId,
    valorTotal: monto,
  });
  await prisma.pago.create({
    data: { ticketId: ticket.id, monto, metodo, turnoId, estado: estadoPago },
  });
  return ticket;
}

describe('POST /api/v1/turnos', () => {
  it('devuelve 401 sin token', async () => {
    const res = await request(app).post('/api/v1/turnos').send({ baseInicial: 50000 });
    expect(res.status).toBe(401);
  });

  it('abre un turno para el operador autenticado', async () => {
    const res = await request(app)
      .post('/api/v1/turnos')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ baseInicial: 50000 });

    expect(res.status).toBe(201);
    expect(res.body.operadorId).toBe(operador.id);
    expect(res.body.baseInicial).toBe(50000);
    expect(res.body.estado).toBe('ABIERTO');
  });

  it('409 si el operador ya tiene un turno abierto', async () => {
    await createTurnoInDb({ operadorId: operador.id });

    const res = await request(app)
      .post('/api/v1/turnos')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ baseInicial: 50000 });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('TURNO_YA_ABIERTO');
  });
});

describe('POST /api/v1/turnos/:id/cierre', () => {
  it('devuelve 401 sin token', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id });
    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/cierre`)
      .send({ efectivoContado: 50000 });
    expect(res.status).toBe(401);
  });

  it('cuadre exacto: cierra con diferencia 0 y devuelve el arqueo completo', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id, baseInicial: 50000 });
    await crearTicketCerradoConPago({
      turnoId: turno.id,
      operadorSalidaId: operador.id,
      monto: 20000,
      metodo: 'EFECTIVO',
    });
    await crearTicketCerradoConPago({
      turnoId: turno.id,
      operadorSalidaId: operador.id,
      monto: 15000,
      metodo: 'TARJETA',
    });

    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/cierre`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ efectivoContado: 70000 });

    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('CERRADO');
    expect(res.body.cierre).toBeTruthy();
    expect(res.body.totalesPorMetodo).toEqual({ EFECTIVO: 20000, TARJETA: 15000, TRANSFERENCIA: 0 });
    expect(res.body.totalRecaudado).toBe(35000);
    expect(res.body.efectivoEsperado).toBe(70000);
    expect(res.body.efectivoContado).toBe(70000);
    expect(res.body.diferencia).toBe(0);
    expect(res.body.ticketsCerrados).toBe(2);

    const turnoEnDb = await prisma.turno.findUnique({ where: { id: turno.id } });
    expect(turnoEnDb.estado).toBe('CERRADO');
    expect(turnoEnDb.diferencia).toBe(0);
  });

  it('sobrante: efectivoContado mayor al esperado', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id, baseInicial: 50000 });
    await crearTicketCerradoConPago({
      turnoId: turno.id,
      operadorSalidaId: operador.id,
      monto: 20000,
      metodo: 'EFECTIVO',
    });

    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/cierre`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ efectivoContado: 75000 });

    expect(res.status).toBe(200);
    expect(res.body.efectivoEsperado).toBe(70000);
    expect(res.body.diferencia).toBe(5000);
  });

  it('faltante: efectivoContado menor al esperado', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id, baseInicial: 50000 });
    await crearTicketCerradoConPago({
      turnoId: turno.id,
      operadorSalidaId: operador.id,
      monto: 20000,
      metodo: 'EFECTIVO',
    });

    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/cierre`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ efectivoContado: 60000 });

    expect(res.status).toBe(200);
    expect(res.body.efectivoEsperado).toBe(70000);
    expect(res.body.diferencia).toBe(-10000);
  });

  it('solo cuenta pagos VALIDO: un pago EFECTIVO anulado no infla el efectivo esperado', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id, baseInicial: 50000 });
    await crearTicketCerradoConPago({
      turnoId: turno.id,
      operadorSalidaId: operador.id,
      monto: 20000,
      metodo: 'EFECTIVO',
    });
    await crearTicketCerradoConPago({
      turnoId: turno.id,
      operadorSalidaId: operador.id,
      monto: 9999,
      metodo: 'EFECTIVO',
      estadoPago: 'ANULADO',
    });

    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/cierre`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ efectivoContado: 70000 });

    expect(res.status).toBe(200);
    expect(res.body.efectivoEsperado).toBe(70000);
    expect(res.body.diferencia).toBe(0);
  });

  it('403 si otro operador intenta cerrarlo', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id, baseInicial: 50000 });

    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/cierre`)
      .set('Authorization', `Bearer ${otroOperadorToken}`)
      .send({ efectivoContado: 50000 });

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe('TURNO_AJENO');
  });

  it('200 si un ADMIN cierra el turno de un operador', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id, baseInicial: 50000 });

    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/cierre`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ efectivoContado: 50000 });

    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('CERRADO');
  });

  it('404 si el turno no existe', async () => {
    const res = await request(app)
      .post('/api/v1/turnos/00000000-0000-0000-0000-000000000000/cierre')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ efectivoContado: 0 });

    expect(res.status).toBe(404);
  });

  it('409 si el turno ya está cerrado', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id, estado: 'CERRADO', cierre: new Date() });

    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/cierre`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ efectivoContado: 0 });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('TURNO_YA_CERRADO');
  });

  it('400 si falta efectivoContado en el body', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id });

    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/cierre`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({});

    expect(res.status).toBe(400);
  });

  it('un turno cerrado no puede recibir pagos nuevos: registrar salida con cobro responde 409', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id, baseInicial: 50000 });
    await request(app)
      .post(`/api/v1/turnos/${turno.id}/cierre`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ efectivoContado: 50000 });

    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      horaEntrada: new Date(Date.now() - 90 * 60 * 1000),
    });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/salida`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ metodo: 'EFECTIVO' });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('OPERADOR_SIN_TURNO_ABIERTO');
  });
});

describe('GET /api/v1/turnos/:id/arqueo', () => {
  it('devuelve 401 sin token', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id });
    const res = await request(app).get(`/api/v1/turnos/${turno.id}/arqueo`);
    expect(res.status).toBe(401);
  });

  it('turno ABIERTO: arqueo parcial en vivo, con efectivoContado y diferencia en null', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id, baseInicial: 50000 });
    await crearTicketCerradoConPago({
      turnoId: turno.id,
      operadorSalidaId: operador.id,
      monto: 20000,
      metodo: 'EFECTIVO',
    });

    const res = await request(app)
      .get(`/api/v1/turnos/${turno.id}/arqueo`)
      .set('Authorization', `Bearer ${operadorToken}`);

    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('ABIERTO');
    expect(res.body.efectivoEsperado).toBe(70000);
    expect(res.body.totalRecaudado).toBe(20000);
    expect(res.body.ticketsCerrados).toBe(1);
    expect(res.body.efectivoContado).toBeNull();
    expect(res.body.diferencia).toBeNull();
  });

  it('turno CERRADO: arqueo final con los valores persistidos', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id, baseInicial: 50000 });
    await crearTicketCerradoConPago({
      turnoId: turno.id,
      operadorSalidaId: operador.id,
      monto: 20000,
      metodo: 'EFECTIVO',
    });
    await request(app)
      .post(`/api/v1/turnos/${turno.id}/cierre`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ efectivoContado: 68000 });

    const res = await request(app)
      .get(`/api/v1/turnos/${turno.id}/arqueo`)
      .set('Authorization', `Bearer ${operadorToken}`);

    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('CERRADO');
    expect(res.body.efectivoContado).toBe(68000);
    expect(res.body.diferencia).toBe(-2000);
  });

  it('solo cuenta pagos VALIDO en el total por método', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id, baseInicial: 50000 });
    await crearTicketCerradoConPago({
      turnoId: turno.id,
      operadorSalidaId: operador.id,
      monto: 20000,
      metodo: 'EFECTIVO',
      estadoPago: 'ANULADO',
    });

    const res = await request(app)
      .get(`/api/v1/turnos/${turno.id}/arqueo`)
      .set('Authorization', `Bearer ${operadorToken}`);

    expect(res.status).toBe(200);
    expect(res.body.totalesPorMetodo).toEqual({ EFECTIVO: 0, TARJETA: 0, TRANSFERENCIA: 0 });
    expect(res.body.efectivoEsperado).toBe(50000);
  });

  it('403 si otro operador intenta verlo', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id });

    const res = await request(app)
      .get(`/api/v1/turnos/${turno.id}/arqueo`)
      .set('Authorization', `Bearer ${otroOperadorToken}`);

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe('TURNO_AJENO');
  });

  it('200 si un ADMIN ve el arqueo de un turno ajeno', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id });

    const res = await request(app)
      .get(`/api/v1/turnos/${turno.id}/arqueo`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
  });

  it('404 si el turno no existe', async () => {
    const res = await request(app)
      .get('/api/v1/turnos/00000000-0000-0000-0000-000000000000/arqueo')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(404);
  });
});

describe('GET /api/v1/turnos', () => {
  it('devuelve 401 sin token', async () => {
    const res = await request(app).get('/api/v1/turnos');
    expect(res.status).toBe(401);
  });

  it('lista con paginación por defecto', async () => {
    await createTurnoInDb({ operadorId: operador.id });

    const res = await request(app)
      .get('/api/v1/turnos')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.meta).toEqual({ page: 1, perPage: 20, total: 1 });
    expect(res.body.data).toHaveLength(1);
  });

  it('filtra por estado', async () => {
    await createTurnoInDb({ operadorId: operador.id, estado: 'ABIERTO' });
    await createTurnoInDb({
      operadorId: otroOperador.id,
      estado: 'CERRADO',
      cierre: new Date(),
    });

    const res = await request(app)
      .get('/api/v1/turnos')
      .query({ estado: 'CERRADO' })
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].estado).toBe('CERRADO');
  });

  it('filtra por rango de fechas de apertura', async () => {
    await createTurnoInDb({
      operadorId: operador.id,
      apertura: new Date('2020-01-01T12:00:00.000Z'),
    });
    const turnoReciente = await createTurnoInDb({ operadorId: otroOperador.id });

    const res = await request(app)
      .get('/api/v1/turnos')
      .query({ desde: '2025-01-01T00:00:00.000Z' })
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].id).toBe(turnoReciente.id);
  });

  it('OPERADOR solo ve los suyos, aunque pida el operadorId de otro', async () => {
    await createTurnoInDb({ operadorId: operador.id });
    await createTurnoInDb({ operadorId: otroOperador.id });

    const res = await request(app)
      .get('/api/v1/turnos')
      .query({ operadorId: otroOperador.id })
      .set('Authorization', `Bearer ${operadorToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].operadorId).toBe(operador.id);
  });

  it('ADMIN ve todos y puede filtrar por operadorId', async () => {
    await createTurnoInDb({ operadorId: operador.id });
    await createTurnoInDb({ operadorId: otroOperador.id });

    const resTodos = await request(app)
      .get('/api/v1/turnos')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resTodos.body.data).toHaveLength(2);

    const resFiltrado = await request(app)
      .get('/api/v1/turnos')
      .query({ operadorId: operador.id })
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resFiltrado.body.data).toHaveLength(1);
    expect(resFiltrado.body.data[0].operadorId).toBe(operador.id);
  });
});

describe('POST /api/v1/turnos sin baseInicial (apertura confirmada por el operador, con la automática)', () => {
  it('usa la baseInicial configurada por un ADMIN cuando no se manda ninguna', async () => {
    await createUsuarioInDb({ rol: 'ADMIN', baseInicialTurno: 40000 });

    const res = await request(app)
      .post('/api/v1/turnos')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({});

    expect(res.status).toBe(201);
    expect(res.body.operadorId).toBe(operador.id);
    expect(res.body.estado).toBe('ABIERTO');
    expect(res.body.baseInicial).toBe(40000);
  });

  it('abre incluso sin ningún horario de operación vigente: la apertura ya no depende de la ventana', async () => {
    await createUsuarioInDb({ rol: 'ADMIN', baseInicialTurno: 40000 });

    const res = await request(app)
      .post('/api/v1/turnos')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({});

    expect(res.status).toBe(201);
    expect(res.body.baseInicial).toBe(40000);
  });

  it('422 BASE_INICIAL_NO_CONFIGURADA si ningún ADMIN configuró una', async () => {
    const res = await request(app)
      .post('/api/v1/turnos')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({});

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('BASE_INICIAL_NO_CONFIGURADA');
  });
});

describe('turno automático (resolverTurnoAutomatico vía GET /turnos y /arqueo: solo cierre perezoso)', () => {
  it('pasa a CERRADO_PENDIENTE_ARQUEO un turno abierto cuya ventana ya venció', async () => {
    await createHorarioInDb({ apertura: '08:00', cierre: '21:30' });
    // Muy en el pasado: sin importar cuándo corra la suite, su ventana
    // (ese día + 1h de margen) ya quedó atrás hace años.
    const turno = await createTurnoInDb({
      operadorId: operador.id,
      baseInicial: 50000,
      apertura: new Date('2020-01-01T13:00:00.000Z'),
    });
    await crearTicketCerradoConPago({
      turnoId: turno.id,
      operadorSalidaId: operador.id,
      monto: 20000,
      metodo: 'EFECTIVO',
    });

    const res = await request(app)
      .get(`/api/v1/turnos/${turno.id}/arqueo`)
      .set('Authorization', `Bearer ${operadorToken}`);

    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('CERRADO_PENDIENTE_ARQUEO');
    expect(res.body.efectivoEsperado).toBe(70000);
    expect(res.body.efectivoContado).toBeNull();
    expect(res.body.diferencia).toBeNull();

    const turnoEnDb = await prisma.turno.findUnique({ where: { id: turno.id } });
    expect(turnoEnDb.estado).toBe('CERRADO_PENDIENTE_ARQUEO');
    expect(turnoEnDb.validadoPorId).toBeNull();
  });
});

describe('POST /api/v1/turnos/:id/completar-arqueo', () => {
  function crearPendiente(overrides = {}) {
    return createTurnoInDb({
      operadorId: operador.id,
      baseInicial: 50000,
      estado: 'CERRADO_PENDIENTE_ARQUEO',
      cierre: new Date(),
      totalRecaudado: 20000,
      efectivoEsperado: 70000,
      ...overrides,
    });
  }

  it('devuelve 401 sin token', async () => {
    const turno = await crearPendiente();
    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/completar-arqueo`)
      .send({ efectivoContado: 70000 });
    expect(res.status).toBe(401);
  });

  it('ADMIN completa el arqueo: cierra de verdad y deja validadoPorId/validadoEn', async () => {
    const turno = await crearPendiente();

    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/completar-arqueo`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ efectivoContado: 68000 });

    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('CERRADO');
    expect(res.body.efectivoContado).toBe(68000);
    expect(res.body.diferencia).toBe(-2000);
    expect(res.body.validadoPorId).toBe(admin.id);
    expect(res.body.validadoEn).toBeTruthy();

    const turnoEnDb = await prisma.turno.findUnique({ where: { id: turno.id } });
    expect(turnoEnDb.estado).toBe('CERRADO');
    expect(turnoEnDb.validadoPorId).toBe(admin.id);
  });

  it('403 si un OPERADOR intenta completarlo, aunque sea el dueño del turno', async () => {
    const turno = await crearPendiente();

    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/completar-arqueo`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ efectivoContado: 70000 });

    expect(res.status).toBe(403);
  });

  it('404 si el turno no existe', async () => {
    const res = await request(app)
      .post('/api/v1/turnos/00000000-0000-0000-0000-000000000000/completar-arqueo')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ efectivoContado: 0 });

    expect(res.status).toBe(404);
  });

  it('409 TURNO_NO_PENDIENTE_ARQUEO si el turno sigue ABIERTO', async () => {
    const turno = await createTurnoInDb({ operadorId: operador.id, baseInicial: 50000 });

    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/completar-arqueo`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ efectivoContado: 50000 });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('TURNO_NO_PENDIENTE_ARQUEO');
  });

  it('409 TURNO_NO_PENDIENTE_ARQUEO si el turno ya está CERRADO', async () => {
    const turno = await createTurnoInDb({
      operadorId: operador.id,
      estado: 'CERRADO',
      cierre: new Date(),
    });

    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/completar-arqueo`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ efectivoContado: 0 });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('TURNO_NO_PENDIENTE_ARQUEO');
  });

  it('400 si falta efectivoContado en el body', async () => {
    const turno = await crearPendiente();

    const res = await request(app)
      .post(`/api/v1/turnos/${turno.id}/completar-arqueo`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});

    expect(res.status).toBe(400);
  });
});
