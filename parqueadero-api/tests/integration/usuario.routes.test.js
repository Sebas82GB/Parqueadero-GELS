import { describe, it, expect, beforeEach, afterAll } from 'vitest';
import request from 'supertest';
import { randomUUID } from 'node:crypto';
import { createApp } from '../../src/app.js';
import { signTestToken } from '../helpers/jwt.js';
import { buildUsuarioPayload, createUsuarioInDb } from '../helpers/usuario-fixture.js';
import { resetRefreshTokens, resetUsuarios, resetOperacion, disconnectDb } from '../helpers/db.js';

const app = createApp();
const adminToken = signTestToken({ rol: 'ADMIN' });
const operadorToken = signTestToken({ rol: 'OPERADOR' });

beforeEach(async () => {
  await resetOperacion();
  await resetRefreshTokens();
  await resetUsuarios();
});

afterAll(async () => {
  await disconnectDb();
});

describe('GET /api/v1/usuarios', () => {
  it('devuelve 401 sin token', async () => {
    const res = await request(app).get('/api/v1/usuarios');
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const res = await request(app)
      .get('/api/v1/usuarios')
      .set('Authorization', `Bearer ${operadorToken}`);
    expect(res.status).toBe(403);
  });

  it('lista usuarios con paginación por defecto', async () => {
    await createUsuarioInDb();
    await createUsuarioInDb();

    const res = await request(app)
      .get('/api/v1/usuarios')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.meta).toEqual({ page: 1, perPage: 20, total: 2 });
    expect(res.body.data).toHaveLength(2);
    expect(res.body.data[0].passwordHash).toBeUndefined();
  });

  it('filtra por rol y activo', async () => {
    await createUsuarioInDb({ rol: 'ADMIN', activo: true });
    await createUsuarioInDb({ rol: 'OPERADOR', activo: false });

    const res = await request(app)
      .get('/api/v1/usuarios')
      .query({ rol: 'ADMIN', activo: 'true' })
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].rol).toBe('ADMIN');
  });

  it('devuelve 400 con rol inválido', async () => {
    const res = await request(app)
      .get('/api/v1/usuarios')
      .query({ rol: 'SUPERADMIN' })
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(400);
  });
});

describe('GET /api/v1/usuarios/:id', () => {
  it('devuelve el usuario existente sin passwordHash', async () => {
    const { usuario } = await createUsuarioInDb();

    const res = await request(app)
      .get(`/api/v1/usuarios/${usuario.id}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.email).toBe(usuario.email);
    expect(res.body.passwordHash).toBeUndefined();
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .get(`/api/v1/usuarios/${randomUUID()}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });

  it('devuelve 400 si el id no es UUID', async () => {
    const res = await request(app)
      .get('/api/v1/usuarios/no-es-uuid')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(400);
  });
});

describe('POST /api/v1/usuarios', () => {
  it('crea un usuario con token ADMIN', async () => {
    const payload = buildUsuarioPayload({ rol: 'OPERADOR' });

    const res = await request(app)
      .post('/api/v1/usuarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);

    expect(res.status).toBe(201);
    expect(res.body.email).toBe(payload.email);
    expect(res.body.activo).toBe(true);
    expect(res.body.passwordHash).toBeUndefined();
  });

  it('devuelve 400 si la password tiene menos de 8 caracteres', async () => {
    const payload = buildUsuarioPayload({ password: 'corta' });

    const res = await request(app)
      .post('/api/v1/usuarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);

    expect(res.status).toBe(400);
  });

  it('devuelve 400 con rol inválido', async () => {
    const payload = buildUsuarioPayload({ rol: 'SUPERADMIN' });

    const res = await request(app)
      .post('/api/v1/usuarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);

    expect(res.status).toBe(400);
  });

  it('devuelve 409 si el email ya existe', async () => {
    const payload = buildUsuarioPayload();
    await request(app)
      .post('/api/v1/usuarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);

    const res = await request(app)
      .post('/api/v1/usuarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(payload);

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('EMAIL_DUPLICADO');
  });

  it('devuelve 401 sin token', async () => {
    const res = await request(app).post('/api/v1/usuarios').send(buildUsuarioPayload());
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const res = await request(app)
      .post('/api/v1/usuarios')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send(buildUsuarioPayload());
    expect(res.status).toBe(403);
  });
});

describe('PATCH /api/v1/usuarios/:id', () => {
  it('actualiza un campo parcial', async () => {
    const { usuario } = await createUsuarioInDb();

    const res = await request(app)
      .patch(`/api/v1/usuarios/${usuario.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ nombre: 'Nombre Nuevo' });

    expect(res.status).toBe(200);
    expect(res.body.nombre).toBe('Nombre Nuevo');
  });

  it('desactiva un usuario y ya no puede loguearse', async () => {
    const { usuario, password } = await createUsuarioInDb({ activo: true });

    const patch = await request(app)
      .patch(`/api/v1/usuarios/${usuario.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ activo: false });

    expect(patch.status).toBe(200);
    expect(patch.body.activo).toBe(false);

    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: usuario.email, password });

    expect(login.status).toBe(401);
    expect(login.body.error.code).toBe('CREDENCIALES_INVALIDAS');
  });

  it('devuelve 400 con body vacío', async () => {
    const { usuario } = await createUsuarioInDb();

    const res = await request(app)
      .patch(`/api/v1/usuarios/${usuario.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});

    expect(res.status).toBe(400);
  });

  it('devuelve 404 si el usuario no existe', async () => {
    const res = await request(app)
      .patch(`/api/v1/usuarios/${randomUUID()}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ nombre: 'X' });

    expect(res.status).toBe(404);
  });

  it('devuelve 409 si el email ya pertenece a otro usuario', async () => {
    const { usuario: otro } = await createUsuarioInDb();
    const { usuario } = await createUsuarioInDb();

    const res = await request(app)
      .patch(`/api/v1/usuarios/${usuario.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ email: otro.email });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('EMAIL_DUPLICADO');
  });

  it('devuelve 401 sin token', async () => {
    const { usuario } = await createUsuarioInDb();
    const res = await request(app).patch(`/api/v1/usuarios/${usuario.id}`).send({ nombre: 'X' });
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const { usuario } = await createUsuarioInDb();
    const res = await request(app)
      .patch(`/api/v1/usuarios/${usuario.id}`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ nombre: 'X' });
    expect(res.status).toBe(403);
  });
});
