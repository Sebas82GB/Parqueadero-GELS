import { Router } from 'express';
import { auth } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import {
  idParamSchema,
  crearMensualidadBodySchema,
  actualizarMensualidadBodySchema,
  pagarMensualidadBodySchema,
  listarMensualidadesQuerySchema,
} from '../validators/mensualidad.validator.js';
import {
  listarMensualidades,
  obtenerMensualidadPorId,
  crearMensualidad,
  actualizarMensualidad,
  pagarMensualidad,
  cancelarMensualidad,
} from '../controllers/mensualidad.controller.js';

export const mensualidadRouter = Router();

/**
 * @openapi
 * /mensualidades:
 *   get:
 *     summary: Listar mensualidades
 *     tags: [Mensualidades]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: estadoPago
 *         schema: { type: string, enum: [PAGADA, NO_PAGADA, CANCELADA] }
 *       - in: query
 *         name: placa
 *         schema: { type: string, example: "ABC123" }
 *       - in: query
 *         name: vigencia
 *         schema: { type: string, enum: [VIGENTE, POR_VENCER, VENCIDA] }
 *       - in: query
 *         name: diasPorVencer
 *         schema: { type: integer, default: 7 }
 *         description: Ventana de días hacia adelante usada por vigencia=POR_VENCER
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: perPage
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: Lista paginada de mensualidades
 *       400:
 *         description: Parámetros de filtro o paginación inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 */
mensualidadRouter.get(
  '/',
  auth,
  authorize('ADMIN'),
  validate({ query: listarMensualidadesQuerySchema }),
  listarMensualidades,
);

/**
 * @openapi
 * /mensualidades/{id}:
 *   get:
 *     summary: Obtener una mensualidad por id
 *     tags: [Mensualidades]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Mensualidad encontrada
 *       400:
 *         description: Id inválido
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Mensualidad no encontrada
 */
mensualidadRouter.get(
  '/:id',
  auth,
  authorize('ADMIN'),
  validate({ params: idParamSchema }),
  obtenerMensualidadPorId,
);

/**
 * @openapi
 * /mensualidades:
 *   post:
 *     summary: Crear una mensualidad (crea o reutiliza el vehículo por placa)
 *     tags: [Mensualidades]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [placa, tipoVehiculo, fechaInicio, fechaFin, valorMensualidad]
 *             properties:
 *               placa: { type: string, example: "ABC123" }
 *               tipoVehiculo: { type: string, enum: [CARRO, MOTO, BICICLETA, OTRO] }
 *               propietarioNombre: { type: string }
 *               propietarioTelefono: { type: string }
 *               celdaId: { type: string, format: uuid }
 *               fechaInicio: { type: string, format: date-time }
 *               fechaFin: { type: string, format: date-time }
 *               valorMensualidad: { type: integer, minimum: 1, example: 180000 }
 *     responses:
 *       201:
 *         description: Mensualidad creada, estadoPago inicial NO_PAGADA
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Celda no encontrada
 *       409:
 *         description: El vehículo ya tiene una mensualidad con fechas que se solapan
 */
mensualidadRouter.post(
  '/',
  auth,
  authorize('ADMIN'),
  validate({ body: crearMensualidadBodySchema }),
  crearMensualidad,
);

/**
 * @openapi
 * /mensualidades/{id}:
 *   patch:
 *     summary: Actualizar fechas, valor o celda de una mensualidad
 *     tags: [Mensualidades]
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
 *               fechaInicio: { type: string, format: date-time }
 *               fechaFin: { type: string, format: date-time }
 *               valorMensualidad: { type: integer, minimum: 1 }
 *               celdaId: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Mensualidad actualizada
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Mensualidad o celda no encontrada
 *       409:
 *         description: La mensualidad está cancelada o las fechas se solapan con otra
 */
mensualidadRouter.patch(
  '/:id',
  auth,
  authorize('ADMIN'),
  validate({ params: idParamSchema, body: actualizarMensualidadBodySchema }),
  actualizarMensualidad,
);

/**
 * @openapi
 * /mensualidades/{id}/pagar:
 *   post:
 *     summary: Marcar una mensualidad como pagada y registrar el pago en el turno abierto de quien llama
 *     tags: [Mensualidades]
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
 *             required: [metodo]
 *             properties:
 *               metodo: { type: string, enum: [EFECTIVO, TARJETA, TRANSFERENCIA] }
 *     responses:
 *       200:
 *         description: Mensualidad pagada, Pago creado en el turno abierto
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN u OPERADOR)
 *       404:
 *         description: Mensualidad no encontrada
 *       409:
 *         description: La mensualidad está cancelada, ya está pagada o no tiene turno abierto
 */
mensualidadRouter.post(
  '/:id/pagar',
  auth,
  authorize('ADMIN', 'OPERADOR'),
  validate({ params: idParamSchema, body: pagarMensualidadBodySchema }),
  pagarMensualidad,
);

/**
 * @openapi
 * /mensualidades/{id}/cancelar:
 *   post:
 *     summary: Cancelar una mensualidad
 *     tags: [Mensualidades]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Mensualidad cancelada
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Mensualidad no encontrada
 *       409:
 *         description: La mensualidad ya está cancelada
 */
mensualidadRouter.post(
  '/:id/cancelar',
  auth,
  authorize('ADMIN'),
  validate({ params: idParamSchema }),
  cancelarMensualidad,
);
