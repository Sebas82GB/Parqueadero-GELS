import { describe, it, expect, beforeEach, afterEach, afterAll, vi } from 'vitest';
import request from 'supertest';
import { randomUUID } from 'node:crypto';
import { createApp } from '../../src/app.js';
import { prisma } from '../../src/config/database.js';
import { signTestToken } from '../helpers/jwt.js';
import { createUsuarioInDb } from '../helpers/usuario-fixture.js';
import { createCeldaInDb } from '../helpers/celda-fixture.js';
import { createVehiculoInDb } from '../helpers/vehiculo-fixture.js';
import { createTarifaInDb } from '../helpers/tarifa-fixture.js';
import { createHorarioInDb } from '../helpers/horario-fixture.js';
import { createTurnoInDb } from '../helpers/turno-fixture.js';
import { createMensualidadInDb } from '../helpers/mensualidad-fixture.js';
import { buildEntradaPayload, createTicketInDb } from '../helpers/ticket-fixture.js';
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
let adminToken;
let operadorToken;

beforeEach(async () => {
  await resetOperacion();
  await resetRefreshTokens();
  await resetUsuarios();
  await resetCeldas();
  await resetTarifas();
  await resetHorariosOperacion();

  ({ usuario: admin } = await createUsuarioInDb({ rol: 'ADMIN' }));
  ({ usuario: operador } = await createUsuarioInDb({ rol: 'OPERADOR' }));
  adminToken = signTestToken({ id: admin.id, rol: 'ADMIN' });
  operadorToken = signTestToken({ id: operador.id, rol: 'OPERADOR' });
});

afterAll(async () => {
  await disconnectDb();
});

describe('POST /api/v1/tickets', () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('registra la entrada, ocupa la celda y crea el vehículo normalizado', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
    await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    await createHorarioInDb();
    const payload = { placa: ' abc-123 ', tipoVehiculo: 'CARRO', celdaId: celda.id };

    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send(payload);

    expect(res.status).toBe(201);
    expect(res.body.estado).toBe('ABIERTO');
    expect(res.body.codigo).toBeTruthy();
    expect(res.body.horaEntrada).toBeTruthy();
    expect(res.body.vehiculo.placa).toBe('ABC-123');
    expect(res.body.celda.estado).toBe('OCUPADA');

    const celdaEnDb = await prisma.celda.findUnique({ where: { id: celda.id } });
    expect(celdaEnDb.estado).toBe('OCUPADA');
  });

  it('reutiliza el vehículo existente e ignora el tipo del payload', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'MOTO', estado: 'LIBRE' });
    await createTarifaInDb({ tipoVehiculo: 'MOTO' });
    await createHorarioInDb();
    const vehiculo = await createVehiculoInDb({ tipo: 'MOTO' });

    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ placa: vehiculo.placa, tipoVehiculo: 'CARRO', celdaId: celda.id });

    expect(res.status).toBe(201);
    expect(res.body.vehiculo.id).toBe(vehiculo.id);
    expect(res.body.vehiculo.tipo).toBe('MOTO');
  });

  it('devuelve 400 con body inválido', async () => {
    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ placa: 'ABC123' });

    expect(res.status).toBe(400);
  });

  it('devuelve 401 sin token', async () => {
    const res = await request(app).post('/api/v1/tickets').send(buildEntradaPayload());
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token ADMIN', async () => {
    const celda = await createCeldaInDb({ estado: 'LIBRE' });
    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ ...buildEntradaPayload(), celdaId: celda.id });

    expect(res.status).toBe(403);
  });

  it('devuelve 404 si la celda no existe', async () => {
    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ ...buildEntradaPayload(), celdaId: randomUUID() });

    expect(res.status).toBe(404);
  });

  it('devuelve 409 CELDA_OCUPADA si la celda ya está ocupada', async () => {
    const celda = await createCeldaInDb({ estado: 'OCUPADA' });

    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ ...buildEntradaPayload(), celdaId: celda.id });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CELDA_OCUPADA');
  });

  it('devuelve 409 CELDA_EN_MANTENIMIENTO', async () => {
    const celda = await createCeldaInDb({ estado: 'MANTENIMIENTO' });

    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ ...buildEntradaPayload(), celdaId: celda.id });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CELDA_EN_MANTENIMIENTO');
  });

  it('devuelve 409 VEHICULO_CON_TICKET_ABIERTO', async () => {
    const celdaOcupada = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celdaOcupada.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });
    const celdaLibre = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });

    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ placa: vehiculo.placa, tipoVehiculo: 'CARRO', celdaId: celdaLibre.id });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('VEHICULO_CON_TICKET_ABIERTO');
  });

  it('devuelve 422 CELDA_TIPO_INCOMPATIBLE', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'MOTO', estado: 'LIBRE' });

    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ ...buildEntradaPayload({ tipoVehiculo: 'CARRO' }), celdaId: celda.id });

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('CELDA_TIPO_INCOMPATIBLE');
  });

  it('devuelve 422 TARIFA_NO_VIGENTE si no hay tarifa para el tipo', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'BICICLETA', estado: 'LIBRE' });

    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ ...buildEntradaPayload({ tipoVehiculo: 'BICICLETA' }), celdaId: celda.id });

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('TARIFA_NO_VIGENTE');
  });

  it('devuelve 422 HORARIO_NO_VIGENTE si no hay horario de operación vigente', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
    await createTarifaInDb({ tipoVehiculo: 'CARRO' });

    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ ...buildEntradaPayload({ tipoVehiculo: 'CARRO' }), celdaId: celda.id });

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('HORARIO_NO_VIGENTE');
  });

  it('devuelve 422 FUERA_DE_HORARIO si la entrada es igual o posterior al cierre del horario vigente', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
    await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    await createHorarioInDb();
    vi.setSystemTime(new Date('2026-01-06T02:30:00.000Z'));

    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ ...buildEntradaPayload({ tipoVehiculo: 'CARRO' }), celdaId: celda.id });

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('FUERA_DE_HORARIO');
  });

  it('devuelve 409 CELDA_RESERVADA_MENSUALIDAD si la celda tiene mensualidad vigente de otro vehículo', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
    const dueño = await createVehiculoInDb({ tipo: 'CARRO' });
    await createMensualidadInDb({
      vehiculoId: dueño.id,
      celdaId: celda.id,
      fechaInicio: new Date(Date.now() - 24 * 60 * 60 * 1000),
      fechaFin: new Date(Date.now() + 24 * 60 * 60 * 1000),
    });

    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ ...buildEntradaPayload({ tipoVehiculo: 'CARRO' }), celdaId: celda.id });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CELDA_RESERVADA_MENSUALIDAD');
  });

  it('permite la entrada del propio vehículo de la mensualidad en su celda reservada', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
    await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    await createHorarioInDb();
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      fechaInicio: new Date(Date.now() - 24 * 60 * 60 * 1000),
      fechaFin: new Date(Date.now() + 24 * 60 * 60 * 1000),
    });

    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ placa: vehiculo.placa, tipoVehiculo: 'CARRO', celdaId: celda.id });

    expect(res.status).toBe(201);
  });
});

describe('POST /api/v1/tickets/:id/salida', () => {
  it('conserva el horario de la entrada si se crea uno nuevo antes de la salida', async () => {
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(new Date('2026-01-05T14:30:00.000Z'));
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
    await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const horarioInicial = await createHorarioInDb();

    const entrada = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ ...buildEntradaPayload({ tipoVehiculo: 'CARRO' }), celdaId: celda.id });
    expect(entrada.status).toBe(201);

    vi.setSystemTime(new Date('2026-01-05T15:00:00.000Z'));
    const nuevoHorario = await request(app)
      .post('/api/v1/horarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ apertura: '09:00', cierre: '09:45' });
    expect(nuevoHorario.status).toBe(201);
    await createTurnoInDb({ operadorId: operador.id });

    const salida = await request(app)
      .post(`/api/v1/tickets/${entrada.body.id}/salida`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ metodo: 'EFECTIVO' });

    expect(salida.status).toBe(200);
    const ticketEnDb = await prisma.ticket.findUnique({ where: { id: entrada.body.id } });
    expect(ticketEnDb.horarioId).toBe(horarioInicial.id);
    expect(salida.body.valorTotal).toBe(3000);
    vi.useRealTimers();
  });

  it('cobra usando la tarifa guardada en el ticket, no la vigente hoy', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifaVieja = await createTarifaInDb({
      tipoVehiculo: 'CARRO',
      valorMinuto: 1,
      valorPlena: 999999,
      vigenteDesde: new Date('2020-01-01T00:00:00.000Z'),
      vigenteHasta: new Date('2025-01-01T00:00:00.000Z'),
    });
    await createTarifaInDb({
      tipoVehiculo: 'CARRO',
      valorMinuto: 100,
      valorPlena: 20000,
      vigenteDesde: new Date('2025-01-01T00:00:00.000Z'),
      vigenteHasta: null,
    });
    const horaEntrada = new Date(Date.now() - 90 * 60 * 1000);
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifaVieja.id,
      operadorEntradaId: operador.id,
      horaEntrada,
    });
    await createTurnoInDb({ operadorId: operador.id });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/salida`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ metodo: 'EFECTIVO' });

    // Rango en vez de valor exacto: el tiempo real transcurrido entre crear el
    // ticket y llamar al endpoint varía unos segundos. Con la tarifa vieja
    // (valorMinuto: 1) el total debe rondar 90; si por error se usara la
    // tarifa nueva (valorMinuto: 100) el total sería >= 9000, muy por
    // encima del límite superior.
    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('PAGADO');
    expect(res.body.valorTotal).toBeGreaterThanOrEqual(90);
    expect(res.body.valorTotal).toBeLessThan(200);
    expect(res.body.desglose).toBeTruthy();
    expect(res.body.pago.monto).toBe(res.body.valorTotal);

    const celdaEnDb = await prisma.celda.findUnique({ where: { id: celda.id } });
    expect(celdaEnDb.estado).toBe('LIBRE');

    expect(res.body.recibo).toMatchObject({
      consecutivo: expect.any(Number),
      fechaEmision: expect.any(String),
      establecimiento: expect.objectContaining({ nombre: expect.any(String) }),
      placa: vehiculo.placa,
      tipoVehiculo: 'CARRO',
      celda: celda.codigo,
      horaEntrada: expect.any(String),
      horaSalida: expect.any(String),
      tiempoTotal: expect.stringMatching(/min$/),
      total: res.body.valorTotal,
      metodoPago: 'EFECTIVO',
      operador: operador.nombre,
    });
    expect(res.body.recibo.desglose).toEqual(res.body.desglose);
  });

  it('con mensualidad vigente cierra en 0 y no crea Pago', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const horaEntrada = new Date(Date.now() - 90 * 60 * 1000);
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      horaEntrada,
    });
    await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      fechaInicio: new Date('2020-01-01T00:00:00.000Z'),
      fechaFin: new Date('2099-01-01T00:00:00.000Z'),
      estadoPago: 'PAGADA',
    });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/salida`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({});

    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('PAGADO');
    expect(res.body.valorTotal).toBe(0);
    expect(res.body.pago).toBeFalsy();
    expect(res.body.recibo.metodoPago).toBeNull();
    expect(res.body.recibo.total).toBe(0);
    expect(res.body.recibo.consecutivo).toEqual(expect.any(Number));
  });

  it('mensualidad reservada para otra celda no exime: cobra el valor real', async () => {
    const celdaReservada = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const horaEntrada = new Date(Date.now() - 90 * 60 * 1000);
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      horaEntrada,
    });
    await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      celdaId: celdaReservada.id,
      fechaInicio: new Date('2020-01-01T00:00:00.000Z'),
      fechaFin: new Date('2099-01-01T00:00:00.000Z'),
      estadoPago: 'PAGADA',
    });
    await createTurnoInDb({ operadorId: operador.id });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/salida`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ metodo: 'EFECTIVO' });

    // Rango en vez de valor exacto: el tiempo real transcurrido varía unos
    // segundos. Tarifa CARRO por defecto (valorMinuto: 100), ~90 min reales:
    // si en cambio hubiera exención por mensualidad, valorTotal sería 0, muy
    // por debajo del límite inferior.
    expect(res.status).toBe(200);
    expect(res.body.valorTotal).toBeGreaterThanOrEqual(9000);
    expect(res.body.valorTotal).toBeLessThan(9500);
    expect(res.body.pago.monto).toBe(res.body.valorTotal);
  });

  it('vehículo OTRO usa el valorManual del body', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'OTRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'OTRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'OTRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });
    await createTurnoInDb({ operadorId: operador.id });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/salida`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ metodo: 'EFECTIVO', valorManual: 15000 });

    expect(res.status).toBe(200);
    expect(res.body.valorTotal).toBe(15000);
  });

  it('devuelve 422 VALOR_MANUAL_REQUERIDO para OTRO sin valorManual', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'OTRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'OTRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'OTRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/salida`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({});

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('VALOR_MANUAL_REQUERIDO');
  });

  it('devuelve 422 METODO_PAGO_REQUERIDO si hay cobro y falta el método', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const horaEntrada = new Date(Date.now() - 90 * 60 * 1000);
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      horaEntrada,
    });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/salida`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({});

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('METODO_PAGO_REQUERIDO');
  });

  it('devuelve 409 OPERADOR_SIN_TURNO_ABIERTO si hay cobro y no tiene turno', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const horaEntrada = new Date(Date.now() - 90 * 60 * 1000);
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      horaEntrada,
    });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/salida`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ metodo: 'EFECTIVO' });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('OPERADOR_SIN_TURNO_ABIERTO');
  });

  it('devuelve 404 si el ticket no existe', async () => {
    const res = await request(app)
      .post(`/api/v1/tickets/${randomUUID()}/salida`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({});

    expect(res.status).toBe(404);
  });

  it('devuelve 409 TICKET_NO_ABIERTO si el ticket ya no está abierto', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      estado: 'ANULADO',
    });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/salida`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({});

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('TICKET_NO_ABIERTO');
  });

  it('devuelve 401 sin token', async () => {
    const res = await request(app).post(`/api/v1/tickets/${randomUUID()}/salida`).send({});
    expect(res.status).toBe(401);
  });

  it('devuelve 403 con token ADMIN', async () => {
    const res = await request(app)
      .post(`/api/v1/tickets/${randomUUID()}/salida`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect(res.status).toBe(403);
  });

  // CLAUDE.md §7: si falla la creación del Pago, la celda NO queda liberada.
  // Se fuerza un choque real contra el unique "pagos_ticket_id_key" (sin
  // mocks) para probar el rollback completo de prisma.$transaction.
  it('si falla la creación del Pago, el ticket sigue ABIERTO y la celda sigue OCUPADA', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const horaEntrada = new Date(Date.now() - 90 * 60 * 1000);
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      horaEntrada,
    });
    const turno = await createTurnoInDb({ operadorId: operador.id });
    await prisma.pago.create({
      data: {
        ticketId: ticket.id,
        monto: 1,
        metodo: 'EFECTIVO',
        turnoId: turno.id,
      },
    });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/salida`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ metodo: 'EFECTIVO' });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('TICKET_YA_TIENE_PAGO');

    const ticketEnDb = await prisma.ticket.findUnique({ where: { id: ticket.id } });
    expect(ticketEnDb.estado).toBe('ABIERTO');
    expect(ticketEnDb.horaSalida).toBeNull();

    const celdaEnDb = await prisma.celda.findUnique({ where: { id: celda.id } });
    expect(celdaEnDb.estado).toBe('OCUPADA');
  });

  // Prueba real de concurrencia (sin mocks): dos salidas disparadas al mismo
  // tiempo pegan contra la BD real y nunca deben recibir el mismo
  // recibo.consecutivo, porque nextval() es atómica a nivel de Postgres.
  it('dos salidas concurrentes reciben consecutivos de recibo distintos', async () => {
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    await createTurnoInDb({ operadorId: operador.id });

    async function crearTicketAbierto() {
      const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
      const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
      return createTicketInDb({
        vehiculoId: vehiculo.id,
        celdaId: celda.id,
        tarifaId: tarifa.id,
        operadorEntradaId: operador.id,
        horaEntrada: new Date(Date.now() - 30 * 60 * 1000),
      });
    }

    const [ticketA, ticketB] = await Promise.all([crearTicketAbierto(), crearTicketAbierto()]);

    const [resA, resB] = await Promise.all([
      request(app)
        .post(`/api/v1/tickets/${ticketA.id}/salida`)
        .set('Authorization', `Bearer ${operadorToken}`)
        .send({ metodo: 'EFECTIVO' }),
      request(app)
        .post(`/api/v1/tickets/${ticketB.id}/salida`)
        .set('Authorization', `Bearer ${operadorToken}`)
        .send({ metodo: 'EFECTIVO' }),
    ]);

    expect(resA.status).toBe(200);
    expect(resB.status).toBe(200);
    expect(resA.body.recibo.consecutivo).toEqual(expect.any(Number));
    expect(resB.body.recibo.consecutivo).toEqual(expect.any(Number));
    expect(resA.body.recibo.consecutivo).not.toBe(resB.body.recibo.consecutivo);
  });
});

describe('GET /api/v1/tickets/:id/preview-cobro', () => {
  it('devuelve valorTotal y desglose por bloques sin tocar el ticket ni la celda', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const horaEntrada = new Date(Date.now() - 90 * 60 * 1000);
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      horaEntrada,
    });

    const res = await request(app)
      .get(`/api/v1/tickets/${ticket.id}/preview-cobro`)
      .set('Authorization', `Bearer ${operadorToken}`);

    // Rango en vez de valor exacto: el tiempo real transcurrido varía unos
    // segundos. Tarifa CARRO por defecto (valorMinuto: 100), ~90 min reales.
    expect(res.status).toBe(200);
    expect(res.body.valorTotal).toBeGreaterThanOrEqual(9000);
    expect(res.body.valorTotal).toBeLessThan(9500);
    expect(res.body.desglose).toBeTruthy();

    const ticketEnDb = await prisma.ticket.findUnique({ where: { id: ticket.id } });
    expect(ticketEnDb.estado).toBe('ABIERTO');
    expect(ticketEnDb.horaSalida).toBeNull();
    expect(ticketEnDb.valorTotal).toBeNull();

    const celdaEnDb = await prisma.celda.findUnique({ where: { id: celda.id } });
    expect(celdaEnDb.estado).toBe('OCUPADA');
  });

  it('con mensualidad vigente devuelve valorTotal 0 con desglose MENSUALIDAD', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });
    await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      fechaInicio: new Date('2020-01-01T00:00:00.000Z'),
      fechaFin: new Date('2099-01-01T00:00:00.000Z'),
      estadoPago: 'PAGADA',
    });

    const res = await request(app)
      .get(`/api/v1/tickets/${ticket.id}/preview-cobro`)
      .set('Authorization', `Bearer ${operadorToken}`);

    expect(res.status).toBe(200);
    expect(res.body.valorTotal).toBe(0);
    expect(res.body.desglose).toEqual([{ tipo: 'MENSUALIDAD', valor: 0 }]);
  });

  it('mensualidad reservada para otra celda no exime: la vista previa muestra el cobro real', async () => {
    const celdaReservada = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const horaEntrada = new Date(Date.now() - 90 * 60 * 1000);
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      horaEntrada,
    });
    await createMensualidadInDb({
      vehiculoId: vehiculo.id,
      celdaId: celdaReservada.id,
      fechaInicio: new Date('2020-01-01T00:00:00.000Z'),
      fechaFin: new Date('2099-01-01T00:00:00.000Z'),
      estadoPago: 'PAGADA',
    });

    const res = await request(app)
      .get(`/api/v1/tickets/${ticket.id}/preview-cobro`)
      .set('Authorization', `Bearer ${operadorToken}`);

    // Rango en vez de valor exacto: el tiempo real transcurrido varía unos
    // segundos. Tarifa CARRO por defecto (valorMinuto: 100), ~90 min reales:
    // si en cambio hubiera exención por mensualidad, valorTotal sería 0, muy
    // por debajo del límite inferior.
    expect(res.status).toBe(200);
    expect(res.body.valorTotal).toBeGreaterThanOrEqual(9000);
    expect(res.body.valorTotal).toBeLessThan(9500);
  });

  it('vehículo OTRO: valorTotal null, indica que el valor lo digita el operador', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'OTRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'OTRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'OTRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });

    const res = await request(app)
      .get(`/api/v1/tickets/${ticket.id}/preview-cobro`)
      .set('Authorization', `Bearer ${operadorToken}`);

    expect(res.status).toBe(200);
    expect(res.body.valorTotal).toBeNull();
    expect(res.body.desglose[0].tipo).toBe('MANUAL');
    expect(res.body.desglose[0].motivo).toEqual(expect.any(String));
  });

  it('permite la consulta con token ADMIN', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });

    const res = await request(app)
      .get(`/api/v1/tickets/${ticket.id}/preview-cobro`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .get(`/api/v1/tickets/${randomUUID()}/preview-cobro`)
      .set('Authorization', `Bearer ${operadorToken}`);
    expect(res.status).toBe(404);
  });

  it('devuelve 409 TICKET_NO_ABIERTO si el ticket ya no está abierto', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      estado: 'ANULADO',
    });

    const res = await request(app)
      .get(`/api/v1/tickets/${ticket.id}/preview-cobro`)
      .set('Authorization', `Bearer ${operadorToken}`);

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('TICKET_NO_ABIERTO');
  });

  it('devuelve 401 sin token', async () => {
    const res = await request(app).get(`/api/v1/tickets/${randomUUID()}/preview-cobro`);
    expect(res.status).toBe(401);
  });
});

describe('GET /api/v1/tickets', () => {
  it('devuelve 401 sin token', async () => {
    const res = await request(app).get('/api/v1/tickets');
    expect(res.status).toBe(401);
  });

  it('lista con paginación por defecto', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });

    const res = await request(app)
      .get('/api/v1/tickets')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.meta).toEqual({ page: 1, perPage: 20, total: 1 });
    expect(res.body.data).toHaveLength(1);
  });

  it('filtra por estado', async () => {
    const celda1 = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo1 = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    await createTicketInDb({
      vehiculoId: vehiculo1.id,
      celdaId: celda1.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      estado: 'ABIERTO',
    });
    const celda2 = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
    const vehiculo2 = await createVehiculoInDb({ tipo: 'CARRO' });
    await createTicketInDb({
      vehiculoId: vehiculo2.id,
      celdaId: celda2.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      estado: 'ANULADO',
    });

    const res = await request(app)
      .get('/api/v1/tickets')
      .query({ estado: 'ANULADO' })
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].estado).toBe('ANULADO');
  });

  it('filtra por placa', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO', placa: 'FILTRO1' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });
    const otraCelda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const otroVehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    await createTicketInDb({
      vehiculoId: otroVehiculo.id,
      celdaId: otraCelda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });

    const res = await request(app)
      .get('/api/v1/tickets')
      .query({ placa: 'filtro1' })
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].vehiculo.placa).toBe('FILTRO1');
  });

  it('filtra por rango de fechas de horaEntrada', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      horaEntrada: new Date('2020-01-01T12:00:00.000Z'),
    });
    const celdaReciente = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculoReciente = await createVehiculoInDb({ tipo: 'CARRO' });
    await createTicketInDb({
      vehiculoId: vehiculoReciente.id,
      celdaId: celdaReciente.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });

    const res = await request(app)
      .get('/api/v1/tickets')
      .query({ desde: '2025-01-01T00:00:00.000Z' })
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].vehiculo.id).toBe(vehiculoReciente.id);
  });
});

describe('GET /api/v1/tickets/:id', () => {
  it('devuelve el ticket con detalle', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });

    const res = await request(app)
      .get(`/api/v1/tickets/${ticket.id}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.id).toBe(ticket.id);
    expect(res.body.vehiculo.id).toBe(vehiculo.id);
    expect(res.body.celda.id).toBe(celda.id);
    expect(res.body.tarifa.id).toBe(tarifa.id);
    expect(res.body.recibo).toBeNull();
  });

  it('recibo trae el mismo consecutivo que devolvió la salida (reimpresión)', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      horaEntrada: new Date(Date.now() - 30 * 60 * 1000),
    });
    await createTurnoInDb({ operadorId: operador.id });

    const resSalida = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/salida`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ metodo: 'EFECTIVO' });
    expect(resSalida.status).toBe(200);

    const resDetalle = await request(app)
      .get(`/api/v1/tickets/${ticket.id}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(resDetalle.status).toBe(200);
    expect(resDetalle.body.recibo).not.toBeNull();
    expect(resDetalle.body.recibo.consecutivo).toBe(resSalida.body.recibo.consecutivo);
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .get(`/api/v1/tickets/${randomUUID()}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });

  it('devuelve 401 sin token', async () => {
    const res = await request(app).get(`/api/v1/tickets/${randomUUID()}`);
    expect(res.status).toBe(401);
  });
});

describe('POST /api/v1/tickets/:id/anular', () => {
  it('anula el ticket con ADMIN y libera la celda', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/anular`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ motivo: 'Se registró la placa equivocada' });

    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('ANULADO');
    expect(res.body.motivoAnulacion).toBe('Se registró la placa equivocada');

    const celdaEnDb = await prisma.celda.findUnique({ where: { id: celda.id } });
    expect(celdaEnDb.estado).toBe('LIBRE');
  });

  it('devuelve 403 con token OPERADOR', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/anular`)
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({ motivo: 'Se registró la placa equivocada' });

    expect(res.status).toBe(403);
  });

  it('devuelve 400 sin motivo', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/anular`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});

    expect(res.status).toBe(400);
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .post(`/api/v1/tickets/${randomUUID()}/anular`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ motivo: 'Motivo válido' });
    expect(res.status).toBe(404);
  });

  it('devuelve 409 si el ticket ya no está abierto', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      estado: 'ANULADO',
    });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/anular`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ motivo: 'Motivo válido' });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('TICKET_NO_ABIERTO');
  });

  it('devuelve 401 sin token', async () => {
    const res = await request(app)
      .post(`/api/v1/tickets/${randomUUID()}/anular`)
      .send({ motivo: 'Motivo válido' });
    expect(res.status).toBe(401);
  });
});

describe('POST /api/v1/tickets/:id/entregar', () => {
  it('marca como entregado un ticket pagado', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'LIBRE' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
      estado: 'PAGADO',
      horaSalida: new Date(),
      valorTotal: 9000,
    });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/entregar`)
      .set('Authorization', `Bearer ${operadorToken}`);

    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('ENTREGADO');
  });

  it('devuelve 409 TICKET_NO_PAGADO si no está pagado', async () => {
    const celda = await createCeldaInDb({ tipoPermitido: 'CARRO', estado: 'OCUPADA' });
    const vehiculo = await createVehiculoInDb({ tipo: 'CARRO' });
    const tarifa = await createTarifaInDb({ tipoVehiculo: 'CARRO' });
    const ticket = await createTicketInDb({
      vehiculoId: vehiculo.id,
      celdaId: celda.id,
      tarifaId: tarifa.id,
      operadorEntradaId: operador.id,
    });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticket.id}/entregar`)
      .set('Authorization', `Bearer ${operadorToken}`);

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('TICKET_NO_PAGADO');
  });

  it('devuelve 404 si no existe', async () => {
    const res = await request(app)
      .post(`/api/v1/tickets/${randomUUID()}/entregar`)
      .set('Authorization', `Bearer ${operadorToken}`);
    expect(res.status).toBe(404);
  });

  it('devuelve 401 sin token', async () => {
    const res = await request(app).post(`/api/v1/tickets/${randomUUID()}/entregar`);
    expect(res.status).toBe(401);
  });
});
