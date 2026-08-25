import { Router } from 'express';
import { auth } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import {
  idParamSchema,
  crearHorarioBodySchema,
  listarHorariosQuerySchema,
} from '../validators/horario-operacion.validator.js';
import {
  listarHorarios,
  obtenerHorarioPorId,
  crearHorario,
  cerrarHorario,
} from '../controllers/horario-operacion.controller.js';

export const horarioOperacionRouter = Router();

/**
 * @openapi
 * /horarios:
 *   get:
 *     summary: Listar horarios de operación
 *     tags: [Horarios]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: vigente
 *         schema: { type: boolean }
 *         description: Filtra por horarios vigentes (true) o históricos (false) al momento actual
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: perPage
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: Lista paginada de horarios de operación
 *       400:
 *         description: Parámetros de filtro o paginación inválidos
 *       401:
 *         description: No autenticado
 */
horarioOperacionRouter.get(
  '/',
  auth,
  validate({ query: listarHorariosQuerySchema }),
  listarHorarios,
);

/**
 * @openapi
 * /horarios/{id}:
 *   get:
 *     summary: Obtener un horario de operación por id
 *     tags: [Horarios]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Horario encontrado
 *       400:
 *         description: Id inválido
 *       401:
 *         description: No autenticado
 *       404:
 *         description: Horario no encontrado
 */
horarioOperacionRouter.get(
  '/:id',
  auth,
  validate({ params: idParamSchema }),
  obtenerHorarioPorId,
);

/**
 * @openapi
 * /horarios:
 *   post:
 *     summary: Crear una nueva vigencia de horario de operación (cierra automáticamente la anterior)
 *     tags: [Horarios]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [apertura, cierre]
 *             properties:
 *               apertura: { type: string, example: "08:00", description: "Hora local, formato HH:mm" }
 *               cierre: { type: string, example: "21:30", description: "Hora local, formato HH:mm" }
 *     responses:
 *       201:
 *         description: Horario creado; el vigente anterior queda cerrado
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 */
horarioOperacionRouter.post(
  '/',
  auth,
  authorize('ADMIN'),
  validate({ body: crearHorarioBodySchema }),
  crearHorario,
);

/**
 * @openapi
 * /horarios/{id}/cerrar:
 *   post:
 *     summary: Cerrar la vigencia de un horario de operación (le pone vigenteHasta, no lo borra)
 *     tags: [Horarios]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Horario cerrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Horario no encontrado
 *       409:
 *         description: El horario ya está cerrado
 */
horarioOperacionRouter.post(
  '/:id/cerrar',
  auth,
  authorize('ADMIN'),
  validate({ params: idParamSchema }),
  cerrarHorario,
);
