import { Router } from 'express';
import { auth } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import {
  idParamSchema,
  crearCeldaBodySchema,
  actualizarCeldaBodySchema,
  listarCeldasQuerySchema,
} from '../validators/celda.validator.js';
import {
  listarCeldas,
  obtenerCeldaPorId,
  crearCelda,
  actualizarCelda,
  marcarMantenimiento,
  volverALibre,
} from '../controllers/celda.controller.js';

export const celdaRouter = Router();

/**
 * @openapi
 * /celdas:
 *   get:
 *     summary: Listar celdas
 *     tags: [Celdas]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: zona
 *         schema: { type: string }
 *       - in: query
 *         name: estado
 *         schema: { type: string, enum: [LIBRE, OCUPADA, MANTENIMIENTO] }
 *       - in: query
 *         name: tipoPermitido
 *         schema: { type: string, enum: [CARRO, MOTO, BICICLETA, OTRO] }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: perPage
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: Lista paginada de celdas
 *       400:
 *         description: Parámetros de filtro o paginación inválidos
 *       401:
 *         description: No autenticado
 */
celdaRouter.get('/', auth, validate({ query: listarCeldasQuerySchema }), listarCeldas);

/**
 * @openapi
 * /celdas/{id}:
 *   get:
 *     summary: Obtener una celda por id
 *     tags: [Celdas]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Celda encontrada
 *       400:
 *         description: Id inválido
 *       401:
 *         description: No autenticado
 *       404:
 *         description: Celda no encontrada
 */
celdaRouter.get('/:id', auth, validate({ params: idParamSchema }), obtenerCeldaPorId);

/**
 * @openapi
 * /celdas:
 *   post:
 *     summary: Crear una celda
 *     tags: [Celdas]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [codigo, zona, tipoPermitido]
 *             properties:
 *               codigo: { type: string, example: "A-12" }
 *               zona: { type: string, example: "Zona A" }
 *               tipoPermitido: { type: string, enum: [CARRO, MOTO, BICICLETA, OTRO] }
 *     responses:
 *       201:
 *         description: Celda creada
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       409:
 *         description: Código de celda duplicado
 */
celdaRouter.post(
  '/',
  auth,
  authorize('ADMIN'),
  validate({ body: crearCeldaBodySchema }),
  crearCelda,
);

/**
 * @openapi
 * /celdas/{id}:
 *   patch:
 *     summary: Actualizar una celda
 *     tags: [Celdas]
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
 *               codigo: { type: string }
 *               zona: { type: string }
 *               tipoPermitido: { type: string, enum: [CARRO, MOTO, BICICLETA, OTRO] }
 *     responses:
 *       200:
 *         description: Celda actualizada
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Celda no encontrada
 *       409:
 *         description: Código de celda duplicado
 */
celdaRouter.patch(
  '/:id',
  auth,
  authorize('ADMIN'),
  validate({ params: idParamSchema, body: actualizarCeldaBodySchema }),
  actualizarCelda,
);

/**
 * @openapi
 * /celdas/{id}/mantenimiento:
 *   patch:
 *     summary: Cambiar una celda a estado MANTENIMIENTO
 *     tags: [Celdas]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Celda puesta en mantenimiento
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Celda no encontrada
 *       409:
 *         description: La celda está ocupada o ya está en mantenimiento
 */
celdaRouter.patch(
  '/:id/mantenimiento',
  auth,
  authorize('ADMIN'),
  validate({ params: idParamSchema }),
  marcarMantenimiento,
);

/**
 * @openapi
 * /celdas/{id}/liberar:
 *   patch:
 *     summary: Volver una celda a estado LIBRE
 *     tags: [Celdas]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Celda liberada
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Celda no encontrada
 *       409:
 *         description: La celda está ocupada o ya está libre
 */
celdaRouter.patch(
  '/:id/liberar',
  auth,
  authorize('ADMIN'),
  validate({ params: idParamSchema }),
  volverALibre,
);
