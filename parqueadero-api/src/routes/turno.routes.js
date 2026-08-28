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
import {
  abrirTurno,
  cerrarTurno,
  completarArqueo,
  obtenerArqueo,
  listarTurnos,
} from '../controllers/turno.controller.js';

export const turnoRouter = Router();

/**
 * @openapi
 * /turnos:
 *   post:
 *     summary: Abrir un turno para el operador autenticado
 *     description: >
 *       El operador siempre confirma esta acción explícitamente (nunca se abre en segundo plano). Si se
 *       omite baseInicial, se usa la que un ADMIN haya configurado para la apertura automática
 *       (`Usuario.baseInicialTurno`) — así el operador no tiene que digitarla cada vez.
 *     tags: [Turnos]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               baseInicial:
 *                 type: integer
 *                 minimum: 0
 *                 example: 50000
 *                 description: Si se omite, se usa la baseInicial automática configurada por un ADMIN.
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
 *       422:
 *         description: Se omitió baseInicial y ningún ADMIN configuró una automática (code BASE_INICIAL_NO_CONFIGURADA)
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
 *     description: >
 *       Un OPERADOR solo ve sus propios turnos, aunque intente filtrar por otro operadorId. Un ADMIN ve
 *       todos y puede filtrar por operadorId. Si quien consulta es OPERADOR y tiene un turno ABIERTO cuya
 *       ventana horaria ya venció, esta llamada lo pasa a CERRADO_PENDIENTE_ARQUEO antes de responder (la
 *       apertura nunca es automática: el operador siempre la confirma con POST /turnos).
 *     tags: [Turnos]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: operadorId
 *         schema: { type: string, format: uuid }
 *         description: Ignorado si quien consulta es OPERADOR (siempre ve los suyos)
 *       - in: query
 *         name: estado
 *         schema: { type: string, enum: [ABIERTO, CERRADO_PENDIENTE_ARQUEO, CERRADO] }
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
 *     description: >
 *       Disponible para un turno ABIERTO (parcial, en vivo — efectivoContado y diferencia llegan en null),
 *       CERRADO_PENDIENTE_ARQUEO (efectivoEsperado ya calculado pero todavía sin efectivoContado) o CERRADO
 *       (final, con los valores ya persistidos). Si el turno está ABIERTO y su ventana horaria ya venció,
 *       esta llamada lo pasa a CERRADO_PENDIENTE_ARQUEO antes de responder.
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

/**
 * @openapi
 * /turnos/{id}/completar-arqueo:
 *   post:
 *     summary: Completar el arqueo de un turno pendiente (solo ADMIN)
 *     description: >
 *       Un turno pasa a CERRADO_PENDIENTE_ARQUEO automáticamente cuando se acaba la ventana horaria y
 *       nadie ha contado el efectivo todavía. Este endpoint recibe ese conteo, calcula la diferencia
 *       contra el efectivoEsperado ya guardado, y cierra el turno de verdad (estado CERRADO), dejando
 *       registro de qué ADMIN lo validó y cuándo (validadoPorId, validadoEn). A diferencia de
 *       POST /turnos/{id}/cierre, no hay excepción para el operador dueño: esta validación es un control
 *       del negocio que solo puede hacer un administrador.
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
 *         description: Turno validado y cerrado, con el arqueo completo
 *         content:
 *           application/json:
 *             schema: { $ref: '#/components/schemas/ArqueoTurno' }
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Turno no encontrado
 *       409:
 *         description: El turno no está pendiente de arqueo (sigue ABIERTO o ya está CERRADO)
 */
turnoRouter.post(
  '/:id/completar-arqueo',
  auth,
  authorize('ADMIN'),
  validate({ params: idParamSchema, body: cerrarTurnoBodySchema }),
  completarArqueo,
);
