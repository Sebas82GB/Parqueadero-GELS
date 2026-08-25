import { describe, it, expect, beforeEach, afterAll } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { env } from '../../src/config/env.js';
import { signTestToken } from '../helpers/jwt.js';
import { createUsuarioInDb } from '../helpers/usuario-fixture.js';
import { resetOperacion, resetRefreshTokens, resetUsuarios, disconnectDb } from '../helpers/db.js';

const app = createApp();

let adminToken;
let operadorToken;

beforeEach(async () => {
  await resetOperacion();
  await resetRefreshTokens();
  await resetUsuarios();

  const { usuario: admin } = await createUsuarioInDb({ rol: 'ADMIN' });
  const { usuario: operador } = await createUsuarioInDb({ rol: 'OPERADOR' });
  adminToken = signTestToken({ id: admin.id, rol: 'ADMIN' });
  operadorToken = signTestToken({ id: operador.id, rol: 'OPERADOR' });
});

afterAll(async () => {
  await disconnectDb();
});

describe('GET /api/v1/establecimiento', () => {
  it('devuelve 401 sin token', async () => {
    const res = await request(app).get('/api/v1/establecimiento');
    expect(res.status).toBe(401);
  });

  it('devuelve los datos configurados con token ADMIN', async () => {
    const res = await request(app)
      .get('/api/v1/establecimiento')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      nombre: env.ESTABLECIMIENTO_NOMBRE,
      nit: env.ESTABLECIMIENTO_NIT,
      direccion: env.ESTABLECIMIENTO_DIRECCION,
      telefono: env.ESTABLECIMIENTO_TELEFONO,
      ciudad: env.ESTABLECIMIENTO_CIUDAD,
      regimenTributario: env.ESTABLECIMIENTO_REGIMEN_TRIBUTARIO,
      numeroResolucion: env.ESTABLECIMIENTO_NUMERO_RESOLUCION,
      textoResponsabilidad: env.ESTABLECIMIENTO_TEXTO_RESPONSABILIDAD,
      textoSeguro: env.ESTABLECIMIENTO_TEXTO_SEGURO,
      textoHorario: env.ESTABLECIMIENTO_TEXTO_HORARIO,
      textoReclamos: env.ESTABLECIMIENTO_TEXTO_RECLAMOS,
    });
  });

  it('permite el acceso también con token OPERADOR', async () => {
    const res = await request(app)
      .get('/api/v1/establecimiento')
      .set('Authorization', `Bearer ${operadorToken}`);

    expect(res.status).toBe(200);
  });
});
