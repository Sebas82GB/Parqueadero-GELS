import { describe, it, expect, beforeEach, afterAll } from 'vitest';
import request from 'supertest';
import { randomUUID } from 'node:crypto';
import { createApp } from '../../src/app.js';
import { signTestToken } from '../helpers/jwt.js';
import { createUsuarioInDb } from '../helpers/usuario-fixture.js';
import { buildHorarioPayload, createHorarioInDb } from '../helpers/horario-fixture.js';
import { createTicketInDb } from '../helpers/ticket-fixture.js';
import {
  resetOperacion,
  resetRefreshTokens,
  resetUsuarios,
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
  await resetHorariosOperacion();

  const { usuario: admin } = await createUsuarioInDb({ rol: 'ADMIN' });
  const { usuario: operador } = await createUsuarioInDb({ rol: 'OPERADOR' });
  adminToken = signTestToken({ id: admin.id, rol: 'ADMIN' });
  operadorToken = signTestToken({ id: operador.id, rol: 'OPERADOR' });
});

afterAll(async () => {
  await disconnectDb();
});

describe('GET /api/v1/horarios', () => {
  it('devuelve 401 sin token', async () => {
    const res = await request(app).get('/api/v1/horarios');
    expect(res.status).toBe(401);
  });

  it('permite listar con ADMIN y con OPERADOR', async () => {
    await createHorarioInDb();

    const resAdmin = await request(app)
      .get('/api/v1/horarios')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resAdmin.status).toBe(200);
    expect(resAdmin.body.data).toHaveLength(1);

    const resOperador = await request(app)
      .get('/api/v1/horarios')
      .set('Authorization', `Bearer ${operadorToken}`);
    expect(resOperador.status).toBe(200);
  });

  it('filtra por vigente=true/false', async () => {
    await createHorarioInDb({
      vigenteDesde: new Date('2020-01-01T00:00:00.000Z'),
      vigenteHasta: new Date('2021-01-01T00:00:00.000Z'),
    });
    await createHorarioInDb({ cierre: '20:00' });

    const resVigentes = await request(app)
      .get('/api/v1/horarios')
      .query({ vigente: 'true' })
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resVigentes.body.data).toHaveLength(1);
    expect(resVigentes.body.data[0].cierre).toBe('20:00');

    const resHistoricos = await request(app)
      .get('/api/v1/horarios')
      .query({ vigente: 'false' })
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resHistoricos.body.data).toHaveLength(1);
    expect(resHistoricos.body.data[0].cierre).toBe('21:30');
  });
});

describe('GET /api/v1/horarios/:id', () => {
  it('devuelve el horario existente', async () => {
    const horario = await createHorarioInDb();

    const res = await request(app)
      .get(`/api/v1/horarios/${horario.id}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.apertura).toBe('08:00');
    expect(res.body.cierre).toBe('21:30');
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .get(`/api/v1/horarios/${randomUUID()}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });

  it('devuelve 400 si el id no es UUID', async () => {
    const res = await request(app)
      .get('/api/v1/horarios/no-es-uuid')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(400);
  });
});

describe('POST /api/v1/horarios', () => {
  it('crea un horario con ADMIN', async () => {
    const res = await request(app)
      .post('/api/v1/horarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(buildHorarioPayload());

    expect(res.status).toBe(201);
    expect(res.body.apertura).toBe('08:00');
    expect(res.body.cierre).toBe('21:30');
    expect(res.body.vigenteHasta).toBeNull();
  });

  it('cierra automáticamente el vigente anterior', async () => {
    const primero = await createHorarioInDb({
      vigenteDesde: new Date('2020-01-01T00:00:00.000Z'),
    });

    const res = await request(app)
      .post('/api/v1/horarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(buildHorarioPayload({ apertura: '07:00' }));

    expect(res.status).toBe(201);

    const resPrimero = await request(app)
      .get(`/api/v1/horarios/${primero.id}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(resPrimero.body.vigenteHasta).not.toBeNull();
    expect(new Date(resPrimero.body.vigenteHasta).toISOString()).toBe(
      new Date(res.body.vigenteDesde).toISOString(),
    );
  });

  it('devuelve 400 si falta un campo', async () => {
    const { cierre, ...payload } = buildHorarioPayload();
    const res = await request(app)
      .post('/api/v1/horarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);
    expect(res.status).toBe(400);
  });

  it('devuelve 400 si cierre no es posterior a apertura', async () => {
    const res = await request(app)
      .post('/api/v1/horarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(buildHorarioPayload({ apertura: '21:30', cierre: '08:00' }));
    expect(res.status).toBe(400);
  });

  it('devuelve 400 con formato de hora inválido', async () => {
    const res = await request(app)
      .post('/api/v1/horarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(buildHorarioPayload({ apertura: '8:00' }));
    expect(res.status).toBe(400);
  });

  it('devuelve 401 sin token', async () => {
    const res = await request(app).post('/api/v1/horarios').send(buildHorarioPayload());
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const res = await request(app)
      .post('/api/v1/horarios')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send(buildHorarioPayload());
    expect(res.status).toBe(403);
  });
});

describe('PATCH /api/v1/horarios/:id', () => {
  it('edita sin tickets y el GET posterior refleja los valores nuevos', async () => {
    const horario = await createHorarioInDb();

    const res = await request(app)
      .patch(`/api/v1/horarios/${horario.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ apertura: '07:00', cierre: '22:00' });

    expect(res.status).toBe(200);
    expect(res.body.apertura).toBe('07:00');
    expect(res.body.cierre).toBe('22:00');

    const resGet = await request(app)
      .get(`/api/v1/horarios/${horario.id}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resGet.body.apertura).toBe('07:00');
    expect(resGet.body.cierre).toBe('22:00');
  });

  it('devuelve 409 HORARIO_CON_TICKETS_ASOCIADOS si el horario tiene un ticket asociado', async () => {
    const horario = await createHorarioInDb();
    await createTicketInDb({ horarioId: horario.id });

    const res = await request(app)
      .patch(`/api/v1/horarios/${horario.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ cierre: '22:00' });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('HORARIO_CON_TICKETS_ASOCIADOS');
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .patch(`/api/v1/horarios/${randomUUID()}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ cierre: '22:00' });
    expect(res.status).toBe(404);
  });

  it('devuelve 400 con body vacío', async () => {
    const horario = await createHorarioInDb();
    const res = await request(app)
      .patch(`/api/v1/horarios/${horario.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect(res.status).toBe(400);
  });

  it('devuelve 400 con campo prohibido (vigenteDesde)', async () => {
    const horario = await createHorarioInDb();
    const res = await request(app)
      .patch(`/api/v1/horarios/${horario.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ vigenteDesde: new Date().toISOString() });
    expect(res.status).toBe(400);
  });

  it('devuelve 422 HORARIO_RANGO_INVALIDO si el cierre resultante no es posterior a la apertura', async () => {
    const horario = await createHorarioInDb({ apertura: '08:00', cierre: '21:30' });
    const res = await request(app)
      .patch(`/api/v1/horarios/${horario.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ apertura: '22:00' });
    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('HORARIO_RANGO_INVALIDO');
  });

  it('devuelve 401 sin token', async () => {
    const horario = await createHorarioInDb();
    const res = await request(app)
      .patch(`/api/v1/horarios/${horario.id}`)
      .send({ cierre: '22:00' });
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const horario = await createHorarioInDb();
    const res = await request(app)
      .patch(`/api/v1/horarios/${horario.id}`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ cierre: '22:00' });
    expect(res.status).toBe(403);
  });
});

describe('POST /api/v1/horarios/:id/cerrar', () => {
  it('cierra un horario vigente', async () => {
    const horario = await createHorarioInDb();

    const res = await request(app)
      .post(`/api/v1/horarios/${horario.id}/cerrar`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.vigenteHasta).not.toBeNull();
  });

  it('devuelve 409 HORARIO_YA_CERRADO si se cierra dos veces', async () => {
    const horario = await createHorarioInDb();
    await request(app)
      .post(`/api/v1/horarios/${horario.id}/cerrar`)
      .set('Authorization', `Bearer ${adminToken}`);

    const res = await request(app)
      .post(`/api/v1/horarios/${horario.id}/cerrar`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('HORARIO_YA_CERRADO');
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .post(`/api/v1/horarios/${randomUUID()}/cerrar`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });

  it('devuelve 401 sin token', async () => {
    const horario = await createHorarioInDb();
    const res = await request(app).post(`/api/v1/horarios/${horario.id}/cerrar`);
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const horario = await createHorarioInDb();
    const res = await request(app)
      .post(`/api/v1/horarios/${horario.id}/cerrar`)
      .set('Authorization', `Bearer ${operadorToken}`);
    expect(res.status).toBe(403);
  });
});
