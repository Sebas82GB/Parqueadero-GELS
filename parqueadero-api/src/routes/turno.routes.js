import { Router } from 'express';
import { auth } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import {
  idParamSchema,
  abrirTurnoBodySchema,
  cerrarTurnoBodySchema,
  listarTurnosQuerySchema,
} from '../validators/turno.validator.js';
import { abrirTurno, cerrarTurno, obtenerArqueo, listarTurnos } from '../controllers/turno.controller.js';

export const turnoRouter = Router();

/**
 * @openapi
 * /turnos:
 *   post:
 *     summary: Abrir un turno para el operador autenticado
 *     tags: [Turnos]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [baseInicial]
 *             properties:
 *               baseInicial: { type: integer, minimum: 0, example: 50000 }
 *     responses:
 *       201:
 *         description: Turno abierto
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere OPERADOR)
 *       409:
 *         description: El operador ya tiene un turno abierto
 */
turnoRouter.post(
  '/',
  auth,
  authorize('OPERADOR'),
  validate({ body: abrirTurnoBodySchema }),
  abrirTurno,
);

/**
 * @openapi
 * /turnos:
 *   get:
 *     summary: Listar turnos
 *     description: Un OPERADOR solo ve sus propios turnos, aunque intente filtrar por otro operadorId. Un ADMIN ve todos y puede filtrar por operadorId.
 *     tags: [Turnos]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: operadorId
 *         schema: { type: string, format: uuid }
 *         description: Ignorado si quien consulta es OPERADOR (siempre ve los suyos)
 *       - in: query
 *         name: estado
 *         schema: { type: string, enum: [ABIERTO, CERRADO] }
 *       - in: query
 *         name: desde
 *         schema: { type: string, format: date-time }
 *         description: Filtra turnos con apertura mayor o igual a esta fecha
 *       - in: query
 *         name: hasta
 *         schema: { type: string, format: date-time }
 *         description: Filtra turnos con apertura menor o igual a esta fecha
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: perPage
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: Lista paginada de turnos
 *       400:
 *         description: Parámetros de filtro o paginación inválidos
 *       401:
 *         description: No autenticado
 */
turnoRouter.get('/', auth, validate({ query: listarTurnosQuerySchema }), listarTurnos);

/**
 * @openapi
 * /turnos/{id}/cierre:
 *   post:
 *     summary: Cerrar un turno con el efectivo contado y el arqueo de caja
 *     description: Calcula el efectivo esperado (baseInicial + pagos EFECTIVO válidos) y la diferencia contra lo contado por el operador. La diferencia se guarda siempre, incluso si es 0. Un turno cerrado no puede reabrirse ni recibir pagos nuevos.
 *     tags: [Turnos]
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
 *             required: [efectivoContado]
 *             properties:
 *               efectivoContado: { type: integer, minimum: 0, example: 185000 }
 *     responses:
 *       200:
 *         description: Turno cerrado, con el arqueo completo (totales por método, tickets cerrados, efectivo esperado/contado y diferencia)
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/ArqueoTurno' }
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN u OPERADOR dueño del turno)
 *       404:
 *         description: Turno no encontrado
 *       409:
 *         description: El turno ya está cerrado
 */
turnoRouter.post(
  '/:id/cierre',
  auth,
  authorize('ADMIN', 'OPERADOR'),
  validate({ params: idParamSchema, body: cerrarTurnoBodySchema }),
  cerrarTurno,
);

/**
 * @openapi
 * /turnos/{id}/arqueo:
 *   get:
 *     summary: Ver el arqueo de un turno
 *     description: Disponible tanto para un turno ABIERTO (parcial, en vivo — efectivoContado y diferencia llegan en null porque todavía no se ha contado caja) como CERRADO (final, con los valores ya persistidos).
 *     tags: [Turnos]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Arqueo del turno
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/ArqueoTurno' }
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN u OPERADOR dueño del turno)
 *       404:
 *         description: Turno no encontrado
 */
turnoRouter.get(
  '/:id/arqueo',
  auth,
  validate({ params: idParamSchema }),
  obtenerArqueo,
);
