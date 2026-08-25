import { describe, it, expect, beforeEach, afterAll } from 'vitest';
import request from 'supertest';
import { randomUUID } from 'node:crypto';
import { createApp } from '../../src/app.js';
import { prisma } from '../../src/config/database.js';
import { signTestToken } from '../helpers/jwt.js';
import { createUsuarioInDb } from '../helpers/usuario-fixture.js';
import { createCeldaInDb } from '../helpers/celda-fixture.js';
import { createVehiculoInDb } from '../helpers/vehiculo-fixture.js';
import { createTurnoInDb } from '../helpers/turno-fixture.js';
import { buildMensualidadPayload, createMensualidadInDb } from '../helpers/mensualidad-fixture.js';
import {
  resetOperacion,
  resetRefreshTokens,
  resetUsuarios,
  resetCeldas,
  disconnectDb,
} from '../helpers/db.js';

const app = createApp();
const UN_DIA_MS = 24 * 60 * 60 * 1000;

let admin;
let operador;
let adminToken;
let operadorToken;

beforeEach(async () => {
  await resetOperacion();
  await resetRefreshTokens();
  await resetUsuarios();
  await resetCeldas();

  ({ usuario: admin } = await createUsuarioInDb({ rol: 'ADMIN' }));
  ({ usuario: operador } = await createUsuarioInDb({ rol: 'OPERADOR' }));
  adminToken = signTestToken({ id: admin.id, rol: 'ADMIN' });
  operadorToken = signTestToken({ id: operador.id, rol: 'OPERADOR' });
});

afterAll(async () => {
  await disconnectDb();
});

describe('GET /api/v1/mensualidades', () => {
  it('devuelve 401 sin token', async () => {
    const res = await request(app).get('/api/v1/mensualidades');
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const res = await request(app)
      .get('/api/v1/mensualidades')
      .set('Authorization', `Bearer ${operadorToken}`);
    expect(res.status).toBe(403);
  });

  it('filtra por estadoPago', async () => {
    const v1 = await createVehiculoInDb();
    await createMensualidadInDb({ vehiculoId: v1.id, estadoPago: 'PAGADA' });
    const v2 = await createVehiculoInDb();
    await createMensualidadInDb({ vehiculoId: v2.id, estadoPago: 'NO_PAGADA' });

    const res = await request(app)
      .get('/api/v1/mensualidades')
      .query({ estadoPago: 'PAGADA' })
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].estadoPago).toBe('PAGADA');
  });

  it('filtra por placa', async () => {
    const conocido = await createVehiculoInDb({ placa: 'FIL0001' });
    await createMensualidadInDb({ vehiculoId: conocido.id });
    const otro = await createVehiculoInDb();
    await createMensualidadInDb({ vehiculoId: otro.id });

    const res = await request(app)
      .get('/api/v1/mensualidades')
      .query({ placa: 'FIL0001' })
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
  });

  it('filtra por vigencia=VIGENTE y vigencia=VENCIDA', async () => {
    const ahora = Date.now();

    const vigenteVehiculo = await createVehiculoInDb();
    await createMensualidadInDb({
      vehiculoId: vigenteVehiculo.id,
      fechaInicio: new Date(ahora - 10 * UN_DIA_MS),
      fechaFin: new Date(ahora + 10 * UN_DIA_MS),
    });

    const vencidaVehiculo = await createVehiculoInDb();
    await createMensualidadInDb({
      vehiculoId: vencidaVehiculo.id,
      fechaInicio: new Date(ahora - 60 * UN_DIA_MS),
      fechaFin: new Date(ahora - 30 * UN_DIA_MS),
    });

    const resVigentes = await request(app)
      .get('/api/v1/mensualidades')
      .query({ vigencia: 'VIGENTE' })
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resVigentes.body.data).toHaveLength(1);

    const resVencidas = await request(app)
      .get('/api/v1/mensualidades')
      .query({ vigencia: 'VENCIDA' })
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resVencidas.body.data).toHaveLength(1);
  });
});

describe('GET /api/v1/mensualidades/:id', () => {
  it('devuelve la mensualidad existente', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({ vehiculoId: vehiculo.id });

    const res = await request(app)
      .get(`/api/v1/mensualidades/${mensualidad.id}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.id).toBe(mensualidad.id);
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .get(`/api/v1/mensualidades/${randomUUID()}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });

  it('devuelve 400 si el id no es UUID', async () => {
    const res = await request(app)
      .get('/api/v1/mensualidades/no-es-uuid')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(400);
  });
});

describe('POST /api/v1/mensualidades', () => {
  it('crea la mensualidad y el vehículo si la placa no existía', async () => {
    const payload = buildMensualidadPayload({ placa: 'NEW0001' });

    const res = await request(app)
      .post('/api/v1/mensualidades')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);

    expect(res.status).toBe(201);
    expect(res.body.estadoPago).toBe('NO_PAGADA');

    const vehiculo = await prisma.vehiculo.findUnique({ where: { placa: 'NEW0001' } });
    expect(vehiculo).not.toBeNull();
    expect(vehiculo.tipo).toBe('CARRO');
  });

  it('reutiliza el vehículo existente y conserva su tipo guardado', async () => {
    await createVehiculoInDb({ placa: 'REU0001', tipo: 'MOTO' });
    const payload = buildMensualidadPayload({ placa: 'reu0001', tipoVehiculo: 'CARRO' });

    const res = await request(app)
      .post('/api/v1/mensualidades')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);

    expect(res.status).toBe(201);
    const vehiculo = await prisma.vehiculo.findUnique({ where: { placa: 'REU0001' } });
    expect(vehiculo.tipo).toBe('MOTO');
  });

  it('acepta una celda existente', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO' });

    const res = await request(app)
      .post('/api/v1/mensualidades')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(buildMensualidadPayload({ celdaId: celda.id }));

    expect(res.status).toBe(201);
    expect(res.body.celdaId).toBe(celda.id);
  });

  it('devuelve 404 CELDA_NO_ENCONTRADA si celdaId no existe', async () => {
    const res = await request(app)
      .post('/api/v1/mensualidades')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(buildMensualidadPayload({ celdaId: randomUUID() }));

    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('CELDA_NO_ENCONTRADA');
  });

  it('devuelve 409 MENSUALIDAD_SOLAPADA si las fechas se solapan para la misma placa', async () => {
    const placa = 'SOL0001';
    await request(app)
      .post('/api/v1/mensualidades')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(
        buildMensualidadPayload({
          placa,
          fechaInicio: '2026-01-01T00:00:00.000Z',
          fechaFin: '2026-02-01T00:00:00.000Z',
        }),
      );

    const res = await request(app)
      .post('/api/v1/mensualidades')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(
        buildMensualidadPayload({
          placa,
          fechaInicio: '2026-01-15T00:00:00.000Z',
          fechaFin: '2026-03-01T00:00:00.000Z',
        }),
      );

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('MENSUALIDAD_SOLAPADA');
  });

  it('devuelve 400 si fechaFin no es posterior a fechaInicio', async () => {
    const res = await request(app)
      .post('/api/v1/mensualidades')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(
        buildMensualidadPayload({
          fechaInicio: '2026-02-01T00:00:00.000Z',
          fechaFin: '2026-01-01T00:00:00.000Z',
        }),
      );
    expect(res.status).toBe(400);
  });

  it('devuelve 401 sin token', async () => {
    const res = await request(app).post('/api/v1/mensualidades').send(buildMensualidadPayload());
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const res = await request(app)
      .post('/api/v1/mensualidades')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send(buildMensualidadPayload());
    expect(res.status).toBe(403);
  });
});

describe('PATCH /api/v1/mensualidades/:id', () => {
  it('actualiza un campo parcial', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({ vehiculoId: vehiculo.id });

    const res = await request(app)
      .patch(`/api/v1/mensualidades/${mensualidad.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ valorMensualidad: 250000 });

    expect(res.status).toBe(200);
    expect(res.body.valorMensualidad).toBe(250000);
  });

  it('devuelve 400 con body vacío', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({ vehiculoId: vehiculo.id });

    const res = await request(app)
      .patch(`/api/v1/mensualidades/${mensualidad.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});

    expect(res.status).toBe(400);
  });

  it('devuelve 409 MENSUALIDAD_SOLAPADA al mover fechas sobre otra mensualidad del mismo vehículo', async () => {
    const vehiculo = await createVehiculoInDb();
    const primera = await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      fechaInicio: new Date('2026-01-01T00:00:00.000Z'),
      fechaFin: new Date('2026-02-01T00:00:00.000Z'),
    });
    await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      fechaInicio: new Date('2026-03-01T00:00:00.000Z'),
      fechaFin: new Date('2026-04-01T00:00:00.000Z'),
    });

    const res = await request(app)
      .patch(`/api/v1/mensualidades/${primera.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ fechaFin: '2026-03-15T00:00:00.000Z' });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('MENSUALIDAD_SOLAPADA');
  });

  it('devuelve 409 MENSUALIDAD_CANCELADA si está cancelada', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      estadoPago: 'CANCELADA',
    });

    const res = await request(app)
      .patch(`/api/v1/mensualidades/${mensualidad.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ valorMensualidad: 250000 });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('MENSUALIDAD_CANCELADA');
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .patch(`/api/v1/mensualidades/${randomUUID()}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ valorMensualidad: 250000 });
    expect(res.status).toBe(404);
  });

  it('devuelve 401 sin token', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({ vehiculoId: vehiculo.id });
    const res = await request(app)
      .patch(`/api/v1/mensualidades/${mensualidad.id}`)
      .send({ valorMensualidad: 250000 });
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({ vehiculoId: vehiculo.id });
    const res = await request(app)
      .patch(`/api/v1/mensualidades/${mensualidad.id}`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ valorMensualidad: 250000 });
    expect(res.status).toBe(403);
  });
});

describe('POST /api/v1/mensualidades/:id/pagar', () => {
  it('paga con el turno abierto del operador y crea el Pago', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      estadoPago: 'NO_PAGADA',
      valorMensualidad: 90000,
    });
    const turno = await createTurnoInDb({ operadorId: operador.id });

    const res = await request(app)
      .post(`/api/v1/mensualidades/${mensualidad.id}/pagar`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ metodo: 'EFECTIVO' });

    expect(res.status).toBe(200);
    expect(res.body.estadoPago).toBe('PAGADA');
    expect(res.body.fechaPago).toBeTruthy();

    const pago = await prisma.pago.findFirst({ where: { mensualidadId: mensualidad.id } });
    expect(pago).not.toBeNull();
    expect(pago.monto).toBe(90000);
    expect(pago.metodo).toBe('EFECTIVO');
    expect(pago.turnoId).toBe(turno.id);
    expect(pago.ticketId).toBeNull();
  });

  it('funciona también con token ADMIN si tiene turno abierto', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      estadoPago: 'NO_PAGADA',
    });
    await createTurnoInDb({ operadorId: admin.id });

    const res = await request(app)
      .post(`/api/v1/mensualidades/${mensualidad.id}/pagar`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ metodo: 'EFECTIVO' });

    expect(res.status).toBe(200);
  });

  it('devuelve 409 OPERADOR_SIN_TURNO_ABIERTO sin turno abierto', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      estadoPago: 'NO_PAGADA',
    });

    const res = await request(app)
      .post(`/api/v1/mensualidades/${mensualidad.id}/pagar`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ metodo: 'EFECTIVO' });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('OPERADOR_SIN_TURNO_ABIERTO');
  });

  it('devuelve 409 MENSUALIDAD_YA_PAGADA', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      estadoPago: 'PAGADA',
    });
    await createTurnoInDb({ operadorId: operador.id });

    const res = await request(app)
      .post(`/api/v1/mensualidades/${mensualidad.id}/pagar`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ metodo: 'EFECTIVO' });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('MENSUALIDAD_YA_PAGADA');
  });

  it('devuelve 400 sin metodo', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      estadoPago: 'NO_PAGADA',
    });
    await createTurnoInDb({ operadorId: operador.id });

    const res = await request(app)
      .post(`/api/v1/mensualidades/${mensualidad.id}/pagar`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({});

    expect(res.status).toBe(400);
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .post(`/api/v1/mensualidades/${randomUUID()}/pagar`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ metodo: 'EFECTIVO' });
    expect(res.status).toBe(404);
  });

  it('devuelve 401 sin token', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({ vehiculoId: vehiculo.id });
    const res = await request(app)
      .post(`/api/v1/mensualidades/${mensualidad.id}/pagar`)
      .send({ metodo: 'EFECTIVO' });
    expect(res.status).toBe(401);
  });
});

describe('POST /api/v1/mensualidades/:id/cancelar', () => {
  it('cancela la mensualidad', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({ vehiculoId: vehiculo.id });

    const res = await request(app)
      .post(`/api/v1/mensualidades/${mensualidad.id}/cancelar`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.estadoPago).toBe('CANCELADA');
  });

  it('devuelve 409 MENSUALIDAD_YA_CANCELADA si ya estaba cancelada', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      estadoPago: 'CANCELADA',
    });

    const res = await request(app)
      .post(`/api/v1/mensualidades/${mensualidad.id}/cancelar`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('MENSUALIDAD_YA_CANCELADA');
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .post(`/api/v1/mensualidades/${randomUUID()}/cancelar`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });

  it('devuelve 401 sin token', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({ vehiculoId: vehiculo.id });
    const res = await request(app).post(`/api/v1/mensualidades/${mensualidad.id}/cancelar`);
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const vehiculo = await createVehiculoInDb();
    const mensualidad = await createMensualidadInDb({ vehiculoId: vehiculo.id });
    const res = await request(app)
      .post(`/api/v1/mensualidades/${mensualidad.id}/cancelar`)
      .set('Authorization', `Bearer ${operadorToken}`);
    expect(res.status).toBe(403);
  });
});
