import { describe, it, expect, beforeEach, afterAll } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { createUsuarioInDb } from '../helpers/usuario-fixture.js';
import { resetRefreshTokens, resetUsuarios, resetOperacion, disconnectDb } from '../helpers/db.js';

const app = createApp();

beforeEach(async () => {
  await resetOperacion();
  await resetRefreshTokens();
  await resetUsuarios();
});

afterAll(async () => {
  await disconnectDb();
});

describe('POST /api/v1/auth/login', () => {
  it('devuelve 200 con tokens y el usuario sin passwordHash', async () => {
    const { usuario, password } = await createUsuarioInDb({ rol: 'ADMIN' });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: usuario.email, password });

    expect(res.status).toBe(200);
    expect(res.body.accessToken).toEqual(expect.any(String));
    expect(res.body.refreshToken).toEqual(expect.any(String));
    expect(res.body.usuario.email).toBe(usuario.email);
    expect(res.body.usuario.passwordHash).toBeUndefined();
  });

  it('devuelve el mismo 401 para email inexistente, password incorrecta y usuario inactivo', async () => {
    const { usuario } = await createUsuarioInDb();
    const { usuario: inactivo, password: passwordInactivo } = await createUsuarioInDb({
      activo: false,
    });

    const resEmailInexistente = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'no-existe@example.com', password: 'lo-que-sea' });

    const resPasswordIncorrecta = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: usuario.email, password: 'password-incorrecta' });

    const resInactivo = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: inactivo.email, password: passwordInactivo });

    for (const res of [resEmailInexistente, resPasswordIncorrecta, resInactivo]) {
      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('CREDENCIALES_INVALIDAS');
      expect(res.body.error.message).toBe(resEmailInexistente.body.error.message);
    }
  });

  it('devuelve 400 si falta password', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({ email: 'x@example.com' });
    expect(res.status).toBe(400);
  });
});

describe('POST /api/v1/auth/refresh', () => {
  it('rota el refresh token y el token viejo deja de servir', async () => {
    const { usuario, password } = await createUsuarioInDb();
    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: usuario.email, password });

    const res = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: login.body.refreshToken });

    expect(res.status).toBe(200);
    expect(res.body.accessToken).toEqual(expect.any(String));
    expect(res.body.refreshToken).not.toBe(login.body.refreshToken);

    const segundoIntento = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: login.body.refreshToken });

    expect(segundoIntento.status).toBe(401);
  });

  it('devuelve 401 con un refresh token con formato inválido', async () => {
    const res = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: 'esto-no-es-un-jwt' });
    expect(res.status).toBe(401);
  });

  it('devuelve 400 si falta refreshToken', async () => {
    const res = await request(app).post('/api/v1/auth/refresh').send({});
    expect(res.status).toBe(400);
  });
});

describe('POST /api/v1/auth/logout', () => {
  it('invalida el refresh token', async () => {
    const { usuario, password } = await createUsuarioInDb();
    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: usuario.email, password });

    const res = await request(app)
      .post('/api/v1/auth/logout')
      .send({ refreshToken: login.body.refreshToken });
    expect(res.status).toBe(204);

    const intentoRefresh = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: login.body.refreshToken });
    expect(intentoRefresh.status).toBe(401);
  });

  it('es idempotente en un segundo logout con el mismo token', async () => {
    const { usuario, password } = await createUsuarioInDb();
    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: usuario.email, password });

    await request(app).post('/api/v1/auth/logout').send({ refreshToken: login.body.refreshToken });

    const res = await request(app)
      .post('/api/v1/auth/logout')
      .send({ refreshToken: login.body.refreshToken });

    expect(res.status).toBe(204);
  });

  it('devuelve 400 si falta refreshToken', async () => {
    const res = await request(app).post('/api/v1/auth/logout').send({});
    expect(res.status).toBe(400);
  });
});

describe('GET /api/v1/auth/me', () => {
  it('devuelve el usuario autenticado', async () => {
    const { usuario, password } = await createUsuarioInDb();
    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: usuario.email, password });

    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${login.body.accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.id).toBe(usuario.id);
    expect(res.body.email).toBe(usuario.email);
    expect(res.body.passwordHash).toBeUndefined();
  });

  it('devuelve 401 sin token', async () => {
    const res = await request(app).get('/api/v1/auth/me');
    expect(res.status).toBe(401);
  });
});
