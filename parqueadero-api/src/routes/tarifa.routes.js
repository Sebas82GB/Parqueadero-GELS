import { Router } from 'express';
import { auth } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import {
  idParamSchema,
  crearTarifaBodySchema,
  actualizarTarifaBodySchema,
  simularTarifaBodySchema,
  listarTarifasQuerySchema,
} from '../validators/tarifa.validator.js';
import {
  listarTarifas,
  obtenerTarifaPorId,
  crearTarifa,
  actualizarTarifa,
  cerrarTarifa,
  simularTarifa,
} from '../controllers/tarifa.controller.js';

export const tarifaRouter = Router();

/**
 * @openapi
 * /tarifas:
 *   get:
 *     summary: Listar tarifas
 *     tags: [Tarifas]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: tipoVehiculo
 *         schema: { type: string, enum: [CARRO, MOTO, BICICLETA, OTRO] }
 *       - in: query
 *         name: vigente
 *         schema: { type: boolean }
 *         description: Filtra por tarifas vigentes (true) o históricas (false) al momento actual
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: perPage
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: Lista paginada de tarifas
 *       400:
 *         description: Parámetros de filtro o paginación inválidos
 *       401:
 *         description: No autenticado
 */
tarifaRouter.get('/', auth, validate({ query: listarTarifasQuerySchema }), listarTarifas);

/**
 * @openapi
 * /tarifas/{id}:
 *   get:
 *     summary: Obtener una tarifa por id
 *     tags: [Tarifas]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Tarifa encontrada
 *       400:
 *         description: Id inválido
 *       401:
 *         description: No autenticado
 *       404:
 *         description: Tarifa no encontrada
 */
tarifaRouter.get('/:id', auth, validate({ params: idParamSchema }), obtenerTarifaPorId);

/**
 * @openapi
 * /tarifas:
 *   post:
 *     summary: Crear una nueva vigencia de tarifa (cierra automáticamente la anterior del mismo tipo)
 *     tags: [Tarifas]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [tipoVehiculo, valorMinuto, valorPlena, valorNocturna, valorMes]
 *             properties:
 *               tipoVehiculo: { type: string, enum: [CARRO, MOTO, BICICLETA, OTRO] }
 *               valorMinuto: { type: integer, minimum: 0, example: 100 }
 *               valorPlena: { type: integer, minimum: 0, example: 20000 }
 *               valorNocturna: { type: integer, minimum: 0, example: 16000 }
 *               valorMes: { type: integer, minimum: 0, example: 180000 }
 *     responses:
 *       201:
 *         description: Tarifa creada; la vigente anterior del mismo tipo queda cerrada
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 */
tarifaRouter.post(
  '/',
  auth,
  authorize('ADMIN'),
  validate({ body: crearTarifaBodySchema }),
  crearTarifa,
);

/**
 * @openapi
 * /tarifas/{id}:
 *   patch:
 *     summary: Actualizar una tarifa (solo si no tiene tickets asociados)
 *     tags: [Tarifas]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               valorMinuto: { type: integer, minimum: 0, example: 100 }
 *               valorPlena: { type: integer, minimum: 0, example: 20000 }
 *               valorNocturna: { type: integer, minimum: 0, example: 16000 }
 *               valorMes: { type: integer, minimum: 0, example: 180000 }
 *     responses:
 *       200:
 *         description: Tarifa actualizada
 *       400:
 *         description: Datos inválidos o body vacío
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Tarifa no encontrada
 *       409:
 *         description: La tarifa ya tiene tickets asociados
 */
tarifaRouter.patch(
  '/:id',
  auth,
  authorize('ADMIN'),
  validate({ params: idParamSchema, body: actualizarTarifaBodySchema }),
  actualizarTarifa,
);

/**
 * @openapi
 * /tarifas/{id}/cerrar:
 *   post:
 *     summary: Cerrar la vigencia de una tarifa (le pone vigenteHasta, no la borra)
 *     tags: [Tarifas]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Tarifa cerrada
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Tarifa no encontrada
 *       409:
 *         description: La tarifa ya está cerrada
 */
tarifaRouter.post(
  '/:id/cerrar',
  auth,
  authorize('ADMIN'),
  validate({ params: idParamSchema }),
  cerrarTarifa,
);

/**
 * @openapi
 * /tarifas/simular:
 *   post:
 *     summary: Simular el cobro de una tarifa hipotética para una duración dada (vista previa antes de guardar)
 *     tags: [Tarifas]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [tipoVehiculo, valorMinuto, valorPlena, valorNocturna, duracionMinutos]
 *             properties:
 *               tipoVehiculo: { type: string, enum: [CARRO, MOTO, BICICLETA, OTRO] }
 *               valorMinuto: { type: integer, minimum: 0, example: 100 }
 *               valorPlena: { type: integer, minimum: 0, example: 20000 }
 *               valorNocturna: { type: integer, minimum: 0, example: 16000 }
 *               duracionMinutos: { type: integer, minimum: 1, example: 90 }
 *               horaEntrada:
 *                 type: string
 *                 format: date-time
 *                 description: >
 *                   Instante de referencia para los cortes de apertura/cierre del
 *                   HorarioOperacion vigente en ese momento; por defecto la hora actual
 *     responses:
 *       200:
 *         description: >
 *           valorTotal y desglose que resultarían de esa tarifa y duración. No persiste nada.
 *           valorTotal es null con desglose tipo MANUAL si tipoVehiculo es OTRO (el valor lo
 *           digita el operador al registrar la salida).
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       422:
 *         description: No hay un horario de operación vigente
 */
tarifaRouter.post(
  '/simular',
  auth,
  authorize('ADMIN'),
  validate({ body: simularTarifaBodySchema }),
  simularTarifa,
);
