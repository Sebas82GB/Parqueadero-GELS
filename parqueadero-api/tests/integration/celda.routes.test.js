import { describe, it, expect, beforeEach, afterAll } from 'vitest';
import request from 'supertest';
import { randomUUID } from 'node:crypto';
import { createApp } from '../../src/app.js';
import { signTestToken } from '../helpers/jwt.js';
import { buildCeldaPayload, createCeldaInDb } from '../helpers/celda-fixture.js';
import { resetCeldas, resetOperacion, disconnectDb } from '../helpers/db.js';

const app = createApp();
const adminToken = signTestToken({ rol: 'ADMIN' });
const operadorToken = signTestToken({ rol: 'OPERADOR' });

beforeEach(async () => {
  await resetOperacion();
  await resetCeldas();
});

afterAll(async () => {
  await disconnectDb();
});

describe('GET /api/v1/celdas', () => {
  it('devuelve 401 sin token', async () => {
    const res = await request(app).get('/api/v1/celdas');
    expect(res.status).toBe(401);
  });

  it('devuelve 401 con token mal formado', async () => {
    const res = await request(app).get('/api/v1/celdas').set('Authorization', 'Token abc');
    expect(res.status).toBe(401);
  });

  it('lista celdas con paginación por defecto', async () => {
    await createCeldaInDb({ codigo: 'L-01' });
    await createCeldaInDb({ codigo: 'L-02' });

    const res = await request(app)
      .get('/api/v1/celdas')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.meta).toEqual({ page: 1, perPage: 20, total: 2 });
    expect(res.body.data).toHaveLength(2);
  });

  it('permite listar con token OPERADOR', async () => {
    const res = await request(app)
      .get('/api/v1/celdas')
      .set('Authorization', `Bearer ${operadorToken}`);
    expect(res.status).toBe(200);
  });

  it('filtra por zona, estado y tipoPermitido', async () => {
    await createCeldaInDb({
      codigo: 'F-01',
      zona: 'Zona Filtro',
      estado: 'LIBRE',
      tipoPermitido: 'MOTO',
    });
    await createCeldaInDb({
      codigo: 'F-02',
      zona: 'Otra Zona',
      estado: 'LIBRE',
      tipoPermitido: 'CARRO',
    });

    const res = await request(app)
      .get('/api/v1/celdas')
      .query({ zona: 'Zona Filtro', estado: 'LIBRE', tipoPermitido: 'MOTO' })
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].codigo).toBe('F-01');
  });

  it('devuelve 400 con estado inválido', async () => {
    const res = await request(app)
      .get('/api/v1/celdas')
      .query({ estado: 'NO_EXISTE' })
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(400);
  });

  it('devuelve 400 con perPage inválido', async () => {
    const res = await request(app)
      .get('/api/v1/celdas')
      .query({ perPage: 0 })
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(400);
  });
});

describe('GET /api/v1/celdas/:id', () => {
  it('devuelve 401 sin token', async () => {
    const res = await request(app).get(`/api/v1/celdas/${randomUUID()}`);
    expect(res.status).toBe(401);
  });

  it('devuelve la celda existente', async () => {
    const celda = await createCeldaInDb({ codigo: 'G-01' });

    const res = await request(app)
      .get(`/api/v1/celdas/${celda.id}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.codigo).toBe('G-01');
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .get(`/api/v1/celdas/${randomUUID()}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });

  it('devuelve 400 si el id no es UUID', async () => {
    const res = await request(app)
      .get('/api/v1/celdas/no-es-uuid')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(400);
  });
});

describe('POST /api/v1/celdas', () => {
  it('crea una celda con token ADMIN', async () => {
    const payload = buildCeldaPayload({ codigo: 'c-10' });

    const res = await request(app)
      .post('/api/v1/celdas')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);

    expect(res.status).toBe(201);
    expect(res.body.codigo).toBe('C-10');
    expect(res.body.estado).toBe('LIBRE');
  });

  it('devuelve 400 si falta codigo', async () => {
    const res = await request(app)
      .post('/api/v1/celdas')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ zona: 'Zona Test', tipoPermitido: 'CARRO' });

    expect(res.status).toBe(400);
  });

  it('devuelve 400 con tipoPermitido inválido', async () => {
    const payload = buildCeldaPayload({ tipoPermitido: 'AVION' });

    const res = await request(app)
      .post('/api/v1/celdas')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);

    expect(res.status).toBe(400);
  });

  it('devuelve 400 si el body incluye estado', async () => {
    const payload = { ...buildCeldaPayload(), estado: 'MANTENIMIENTO' };

    const res = await request(app)
      .post('/api/v1/celdas')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);

    expect(res.status).toBe(400);
  });

  it('devuelve 409 si el código ya existe', async () => {
    const payload = buildCeldaPayload({ codigo: 'DUP-01' });
    await request(app)
      .post('/api/v1/celdas')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);

    const res = await request(app)
      .post('/api/v1/celdas')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);

    expect(res.status).toBe(409);
  });

  it('devuelve 401 sin token', async () => {
    const res = await request(app).post('/api/v1/celdas').send(buildCeldaPayload());
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const res = await request(app)
      .post('/api/v1/celdas')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send(buildCeldaPayload());
    expect(res.status).toBe(403);
  });
});

describe('PATCH /api/v1/celdas/:id', () => {
  it('actualiza un campo parcial', async () => {
    const celda = await createCeldaInDb({ codigo: 'U-01' });

    const res = await request(app)
      .patch(`/api/v1/celdas/${celda.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ zona: 'Zona Nueva' });

    expect(res.status).toBe(200);
    expect(res.body.zona).toBe('Zona Nueva');
  });

  it('devuelve 400 con body vacío', async () => {
    const celda = await createCeldaInDb({ codigo: 'U-02' });

    const res = await request(app)
      .patch(`/api/v1/celdas/${celda.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});

    expect(res.status).toBe(400);
  });

  it('devuelve 404 si la celda no existe', async () => {
    const res = await request(app)
      .patch(`/api/v1/celdas/${randomUUID()}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ zona: 'Zona Nueva' });

    expect(res.status).toBe(404);
  });

  it('devuelve 409 si el código ya pertenece a otra celda', async () => {
    await createCeldaInDb({ codigo: 'U-03' });
    const celda = await createCeldaInDb({ codigo: 'U-04' });

    const res = await request(app)
      .patch(`/api/v1/celdas/${celda.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ codigo: 'U-03' });

    expect(res.status).toBe(409);
  });

  it('devuelve 401 sin token', async () => {
    const celda = await createCeldaInDb({ codigo: 'U-05' });
    const res = await request(app).patch(`/api/v1/celdas/${celda.id}`).send({ zona: 'Zona Nueva' });
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const celda = await createCeldaInDb({ codigo: 'U-06' });
    const res = await request(app)
      .patch(`/api/v1/celdas/${celda.id}`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ zona: 'Zona Nueva' });
    expect(res.status).toBe(403);
  });
});

describe('PATCH /api/v1/celdas/:id/mantenimiento', () => {
  it('pasa de LIBRE a MANTENIMIENTO', async () => {
    const celda = await createCeldaInDb({ codigo: 'M-01', estado: 'LIBRE' });

    const res = await request(app)
      .patch(`/api/v1/celdas/${celda.id}/mantenimiento`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('MANTENIMIENTO');
  });

  it('devuelve 409 CELDA_OCUPADA si está OCUPADA', async () => {
    const celda = await createCeldaInDb({ codigo: 'M-02', estado: 'OCUPADA' });

    const res = await request(app)
      .patch(`/api/v1/celdas/${celda.id}/mantenimiento`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CELDA_OCUPADA');
  });

  it('devuelve 409 CELDA_ESTADO_INVALIDO si ya está en MANTENIMIENTO', async () => {
    const celda = await createCeldaInDb({ codigo: 'M-03', estado: 'MANTENIMIENTO' });

    const res = await request(app)
      .patch(`/api/v1/celdas/${celda.id}/mantenimiento`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CELDA_ESTADO_INVALIDO');
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .patch(`/api/v1/celdas/${randomUUID()}/mantenimiento`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });

  it('devuelve 401 sin token', async () => {
    const celda = await createCeldaInDb({ codigo: 'M-04' });
    const res = await request(app).patch(`/api/v1/celdas/${celda.id}/mantenimiento`);
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const celda = await createCeldaInDb({ codigo: 'M-05' });
    const res = await request(app)
      .patch(`/api/v1/celdas/${celda.id}/mantenimiento`)
      .set('Authorization', `Bearer ${operadorToken}`);
    expect(res.status).toBe(403);
  });
});

describe('PATCH /api/v1/celdas/:id/liberar', () => {
  it('pasa de MANTENIMIENTO a LIBRE', async () => {
    const celda = await createCeldaInDb({ codigo: 'R-01', estado: 'MANTENIMIENTO' });

    const res = await request(app)
      .patch(`/api/v1/celdas/${celda.id}/liberar`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('LIBRE');
  });

  it('devuelve 409 CELDA_OCUPADA si está OCUPADA', async () => {
    const celda = await createCeldaInDb({ codigo: 'R-02', estado: 'OCUPADA' });

    const res = await request(app)
      .patch(`/api/v1/celdas/${celda.id}/liberar`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CELDA_OCUPADA');
  });

  it('devuelve 409 CELDA_ESTADO_INVALIDO si ya está LIBRE', async () => {
    const celda = await createCeldaInDb({ codigo: 'R-03', estado: 'LIBRE' });

    const res = await request(app)
      .patch(`/api/v1/celdas/${celda.id}/liberar`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CELDA_ESTADO_INVALIDO');
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .patch(`/api/v1/celdas/${randomUUID()}/liberar`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });

  it('devuelve 401 sin token', async () => {
    const celda = await createCeldaInDb({ codigo: 'R-04', estado: 'MANTENIMIENTO' });
    const res = await request(app).patch(`/api/v1/celdas/${celda.id}/liberar`);
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const celda = await createCeldaInDb({ codigo: 'R-05', estado: 'MANTENIMIENTO' });
    const res = await request(app)
      .patch(`/api/v1/celdas/${celda.id}/liberar`)
      .set('Authorization', `Bearer ${operadorToken}`);
    expect(res.status).toBe(403);
  });
});
