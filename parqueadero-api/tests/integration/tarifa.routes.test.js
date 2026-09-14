import { describe, it, expect, beforeEach, afterAll } from 'vitest';
import request from 'supertest';
import { randomUUID } from 'node:crypto';
import { createApp } from '../../src/app.js';
import { prisma } from '../../src/config/database.js';
import { signTestToken } from '../helpers/jwt.js';
import { createUsuarioInDb } from '../helpers/usuario-fixture.js';
import { buildTarifaPayload, createTarifaInDb } from '../helpers/tarifa-fixture.js';
import { createHorarioInDb } from '../helpers/horario-fixture.js';
import { createTicketInDb } from '../helpers/ticket-fixture.js';
import {
  resetOperacion,
  resetRefreshTokens,
  resetUsuarios,
  resetTarifas,
  resetHorariosOperacion,
  disconnectDb,
} from '../helpers/db.js';

const app = createApp();

let adminToken;
let operadorToken;

beforeEach(async () => {
  await resetOperacion();
  await resetRefreshTokens();
  await resetUsuarios();
  await resetTarifas();
  await resetHorariosOperacion();

  const { usuario: admin } = await createUsuarioInDb({ rol: 'ADMIN' });
  const { usuario: operador } = await createUsuarioInDb({ rol: 'OPERADOR' });
  adminToken = signTestToken({ id: admin.id, rol: 'ADMIN' });
  operadorToken = signTestToken({ id: operador.id, rol: 'OPERADOR' });
});

afterAll(async () => {
  await disconnectDb();
});

describe('GET /api/v1/tarifas', () => {
  it('devuelve 401 sin token', async () => {
    const res = await request(app).get('/api/v1/tarifas');
    expect(res.status).toBe(401);
  });

  it('permite listar con ADMIN y con OPERADOR', async () => {
    await createTarifaInDb({ tipoVehiculo: 'CARRO' });

    const resAdmin = await request(app)
      .get('/api/v1/tarifas')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resAdmin.status).toBe(200);
    expect(resAdmin.body.data).toHaveLength(1);

    const resOperador = await request(app)
      .get('/api/v1/tarifas')
      .set('Authorization', `Bearer ${operadorToken}`);
    expect(resOperador.status).toBe(200);
  });

  it('filtra por tipoVehiculo', async () => {
    await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    await createTarifaInDb({ tipoVehiculo: 'MOTO' });

    const res = await request(app)
      .get('/api/v1/tarifas')
      .query({ tipoVehiculo: 'MOTO' })
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].tipoVehiculo).toBe('MOTO');
  });

  it('filtra por vigente=true/false', async () => {
    await createTarifaInDb({
      tipoVehiculo: 'CARRO',
      vigenteDesde: new Date('2020-01-01T00:00:00.000Z'),
      vigenteHasta: new Date('2021-01-01T00:00:00.000Z'),
    });
    await createTarifaInDb({ tipoVehiculo: 'MOTO' });

    const resVigentes = await request(app)
      .get('/api/v1/tarifas')
      .query({ vigente: 'true' })
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resVigentes.body.data).toHaveLength(1);
    expect(resVigentes.body.data[0].tipoVehiculo).toBe('MOTO');

    const resHistoricas = await request(app)
      .get('/api/v1/tarifas')
      .query({ vigente: 'false' })
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resHistoricas.body.data).toHaveLength(1);
    expect(resHistoricas.body.data[0].tipoVehiculo).toBe('CARRO');
  });

  it('devuelve 400 con tipoVehiculo inválido', async () => {
    const res = await request(app)
      .get('/api/v1/tarifas')
      .query({ tipoVehiculo: 'AVION' })
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(400);
  });
});

describe('GET /api/v1/tarifas/:id', () => {
  it('devuelve la tarifa existente', async () => {
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });

    const res = await request(app)
      .get(`/api/v1/tarifas/${tarifa.id}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.tipoVehiculo).toBe('CARRO');
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .get(`/api/v1/tarifas/${randomUUID()}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });

  it('devuelve 400 si el id no es UUID', async () => {
    const res = await request(app)
      .get('/api/v1/tarifas/no-es-uuid')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(400);
  });
});

describe('POST /api/v1/tarifas', () => {
  it('crea una tarifa con ADMIN', async () => {
    const res = await request(app)
      .post('/api/v1/tarifas')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(buildTarifaPayload({ tipoVehiculo: 'CARRO' }));

    expect(res.status).toBe(201);
    expect(res.body.tipoVehiculo).toBe('CARRO');
    expect(res.body.vigenteHasta).toBeNull();
  });

  it('cierra automáticamente la vigente anterior del mismo tipo', async () => {
    const primera = await createTarifaInDb({
      tipoVehiculo: 'CARRO',
      vigenteDesde: new Date('2020-01-01T00:00:00.000Z'),
    });

    const res = await request(app)
      .post('/api/v1/tarifas')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(buildTarifaPayload({ tipoVehiculo: 'CARRO', valorMinuto: 200 }));

    expect(res.status).toBe(201);

    const resPrimera = await request(app)
      .get(`/api/v1/tarifas/${primera.id}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(resPrimera.body.vigenteHasta).not.toBeNull();
    expect(new Date(resPrimera.body.vigenteHasta).toISOString()).toBe(
      new Date(res.body.vigenteDesde).toISOString(),
    );
  });

  it('no afecta la vigente de otro tipoVehiculo', async () => {
    const moto = await createTarifaInDb({ tipoVehiculo: 'MOTO' });

    await request(app)
      .post('/api/v1/tarifas')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(buildTarifaPayload({ tipoVehiculo: 'CARRO' }));

    const resMoto = await request(app)
      .get(`/api/v1/tarifas/${moto.id}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resMoto.body.vigenteHasta).toBeNull();
  });

  it('devuelve 400 si falta un campo', async () => {
    const { valorMinuto, ...payload } = buildTarifaPayload();
    const res = await request(app)
      .post('/api/v1/tarifas')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);
    expect(res.status).toBe(400);
  });

  it('devuelve 401 sin token', async () => {
    const res = await request(app).post('/api/v1/tarifas').send(buildTarifaPayload());
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const res = await request(app)
      .post('/api/v1/tarifas')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send(buildTarifaPayload());
    expect(res.status).toBe(403);
  });
});

describe('PATCH /api/v1/tarifas/:id', () => {
  it('edita sin tickets y el GET posterior refleja los valores nuevos', async () => {
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });

    const res = await request(app)
      .patch(`/api/v1/tarifas/${tarifa.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ valorMinuto: 150, valorPlena: 25000 });

    expect(res.status).toBe(200);
    expect(res.body.valorMinuto).toBe(150);
    expect(res.body.valorPlena).toBe(25000);

    const resGet = await request(app)
      .get(`/api/v1/tarifas/${tarifa.id}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resGet.body.valorMinuto).toBe(150);
    expect(resGet.body.valorPlena).toBe(25000);
  });

  it('devuelve 409 TARIFA_CON_TICKETS_ASOCIADOS si la tarifa tiene un ticket asociado', async () => {
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    await createTicketInDb({ tarifaId: tarifa.id, tipoVehiculo: 'CARRO' });

    const res = await request(app)
      .patch(`/api/v1/tarifas/${tarifa.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ valorMinuto: 150 });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('TARIFA_CON_TICKETS_ASOCIADOS');
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .patch(`/api/v1/tarifas/${randomUUID()}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ valorMinuto: 150 });
    expect(res.status).toBe(404);
  });

  it('devuelve 400 con body vacío', async () => {
    const tarifa = await createTarifaInDb();
    const res = await request(app)
      .patch(`/api/v1/tarifas/${tarifa.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect(res.status).toBe(400);
  });

  it('devuelve 400 con campo prohibido (tipoVehiculo)', async () => {
    const tarifa = await createTarifaInDb();
    const res = await request(app)
      .patch(`/api/v1/tarifas/${tarifa.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ tipoVehiculo: 'MOTO' });
    expect(res.status).toBe(400);
  });

  it('devuelve 400 con valor negativo', async () => {
    const tarifa = await createTarifaInDb();
    const res = await request(app)
      .patch(`/api/v1/tarifas/${tarifa.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ valorMinuto: -1 });
    expect(res.status).toBe(400);
  });

  it('devuelve 401 sin token', async () => {
    const tarifa = await createTarifaInDb();
    const res = await request(app)
      .patch(`/api/v1/tarifas/${tarifa.id}`)
      .send({ valorMinuto: 150 });
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const tarifa = await createTarifaInDb();
    const res = await request(app)
      .patch(`/api/v1/tarifas/${tarifa.id}`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ valorMinuto: 150 });
    expect(res.status).toBe(403);
  });
});

describe('POST /api/v1/tarifas/:id/cerrar', () => {
  it('cierra una tarifa vigente', async () => {
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });

    const res = await request(app)
      .post(`/api/v1/tarifas/${tarifa.id}/cerrar`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.vigenteHasta).not.toBeNull();
  });

  it('devuelve 409 TARIFA_YA_CERRADA si se cierra dos veces', async () => {
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    await request(app)
      .post(`/api/v1/tarifas/${tarifa.id}/cerrar`)
      .set('Authorization', `Bearer ${adminToken}`);

    const res = await request(app)
      .post(`/api/v1/tarifas/${tarifa.id}/cerrar`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('TARIFA_YA_CERRADA');
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .post(`/api/v1/tarifas/${randomUUID()}/cerrar`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });

  it('devuelve 401 sin token', async () => {
    const tarifa = await createTarifaInDb();
    const res = await request(app).post(`/api/v1/tarifas/${tarifa.id}/cerrar`);
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const tarifa = await createTarifaInDb();
    const res = await request(app)
      .post(`/api/v1/tarifas/${tarifa.id}/cerrar`)
      .set('Authorization', `Bearer ${operadorToken}`);
    expect(res.status).toBe(403);
  });
});

describe('POST /api/v1/tarifas/simular', () => {
  const payloadCarro = {
    tipoVehiculo: 'CARRO',
    valorMinuto: 100,
    valorPlena: 20000,
    valorNocturna: 16000,
    duracionMinutos: 90,
    horaEntrada: '2026-01-05T13:00:00.000Z', // 8:00 AM Bogotá
  };

  it('devuelve el total exacto de la tabla de referencia, sin persistir nada', async () => {
    await createHorarioInDb();
    const totalAntes = await prisma.tarifa.count();

    const res = await request(app)
      .post('/api/v1/tarifas/simular')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payloadCarro);

    expect(res.status).toBe(200);
    expect(res.body.valorTotal).toBe(9000);
    expect(res.body.desglose).toBeTruthy();

    const totalDespues = await prisma.tarifa.count();
    expect(totalDespues).toBe(totalAntes);
  });

  it('vehículo OTRO: valorTotal null, indica que el valor lo digita el operador', async () => {
    await createHorarioInDb();

    const res = await request(app)
      .post('/api/v1/tarifas/simular')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ ...payloadCarro, tipoVehiculo: 'OTRO' });

    expect(res.status).toBe(200);
    expect(res.body.valorTotal).toBeNull();
    expect(res.body.desglose[0].tipo).toBe('MANUAL');
  });

  it('devuelve 422 HORARIO_NO_VIGENTE si no hay horario de operación vigente', async () => {
    const res = await request(app)
      .post('/api/v1/tarifas/simular')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payloadCarro);

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('HORARIO_NO_VIGENTE');
  });

  it('devuelve 400 si falta duracionMinutos', async () => {
    const { duracionMinutos, ...payload } = payloadCarro;
    const res = await request(app)
      .post('/api/v1/tarifas/simular')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);
    expect(res.status).toBe(400);
  });

  it('devuelve 400 si duracionMinutos no es positivo', async () => {
    const res = await request(app)
      .post('/api/v1/tarifas/simular')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ ...payloadCarro, duracionMinutos: 0 });
    expect(res.status).toBe(400);
  });

  it('devuelve 401 sin token', async () => {
    const res = await request(app).post('/api/v1/tarifas/simular').send(payloadCarro);
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const res = await request(app)
      .post('/api/v1/tarifas/simular')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send(payloadCarro);
    expect(res.status).toBe(403);
  });
});
