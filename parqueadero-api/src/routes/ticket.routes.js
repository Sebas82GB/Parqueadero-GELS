import { Router } from 'express';
import { auth } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import {
  idParamSchema,
  registrarEntradaBodySchema,
  registrarSalidaBodySchema,
  anularTicketBodySchema,
  listarTicketsQuerySchema,
} from '../validators/ticket.validator.js';
import {
  listarTickets,
  obtenerTicketPorId,
  previsualizarCobro,
  registrarEntrada,
  registrarSalida,
  anularTicket,
  entregarTicket,
} from '../controllers/ticket.controller.js';

export const ticketRouter = Router();

/**
 * @openapi
 * /tickets:
 *   get:
 *     summary: Listar tickets
 *     tags: [Tickets]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: estado
 *         schema: { type: string, enum: [ABIERTO, PAGADO, ENTREGADO, ANULADO] }
 *       - in: query
 *         name: vehiculoId
 *         schema: { type: string, format: uuid }
 *       - in: query
 *         name: celdaId
 *         schema: { type: string, format: uuid }
 *       - in: query
 *         name: placa
 *         schema: { type: string, example: "ABC123" }
 *       - in: query
 *         name: desde
 *         schema: { type: string, format: date-time }
 *         description: Filtra tickets con horaEntrada mayor o igual a esta fecha
 *       - in: query
 *         name: hasta
 *         schema: { type: string, format: date-time }
 *         description: Filtra tickets con horaEntrada menor o igual a esta fecha
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: perPage
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: Lista paginada de tickets
 *       400:
 *         description: Parámetros de filtro o paginación inválidos
 *       401:
 *         description: No autenticado
 */
ticketRouter.get('/', auth, validate({ query: listarTicketsQuerySchema }), listarTickets);

/**
 * @openapi
 * /tickets/{id}:
 *   get:
 *     summary: Obtener un ticket por id, con vehículo, celda, tarifa y pago
 *     tags: [Tickets]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Ticket encontrado, con recibo (null si sigue ABIERTO)
 *       400:
 *         description: Id inválido
 *       401:
 *         description: No autenticado
 *       404:
 *         description: Ticket no encontrado
 */
ticketRouter.get('/:id', auth, validate({ params: idParamSchema }), obtenerTicketPorId);

/**
 * @openapi
 * /tickets/{id}/preview-cobro:
 *   get:
 *     summary: Previsualizar el cobro de un ticket abierto, calculado a la hora actual, sin cerrarlo
 *     tags: [Tickets]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: >
 *           valorTotal y desglose que resultarían si la salida se registrara ahora mismo, sin
 *           tocar el ticket, la celda ni el pago. valorTotal es 0 con desglose tipo MENSUALIDAD
 *           si el vehículo tiene mensualidad vigente, o null con desglose tipo MANUAL si el
 *           vehículo es tipo OTRO (el valor lo digita el operador al registrar la salida).
 *       400:
 *         description: Id inválido
 *       401:
 *         description: No autenticado
 *       404:
 *         description: Ticket no encontrado
 *       409:
 *         description: El ticket ya no está abierto
 */
ticketRouter.get(
  '/:id/preview-cobro',
  auth,
  validate({ params: idParamSchema }),
  previsualizarCobro,
);

/**
 * @openapi
 * /tickets:
 *   post:
 *     summary: Registrar la entrada de un vehículo
 *     tags: [Tickets]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [placa, tipoVehiculo, celdaId]
 *             properties:
 *               placa: { type: string, example: "ABC123" }
 *               tipoVehiculo: { type: string, enum: [CARRO, MOTO, BICICLETA, OTRO] }
 *               celdaId: { type: string, format: uuid }
 *               propietarioNombre: { type: string }
 *               propietarioTelefono: { type: string }
 *     responses:
 *       201:
 *         description: Ticket abierto, celda pasa a OCUPADA
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere OPERADOR)
 *       404:
 *         description: Celda no encontrada
 *       409:
 *         description: Celda ocupada o el vehículo ya tiene un ticket abierto
 *       422:
 *         description: Celda incompatible con el tipo de vehículo, sin tarifa u horario de operación vigente, o hora de entrada igual o posterior al cierre
 */
ticketRouter.post(
  '/',
  auth,
  authorize('OPERADOR'),
  validate({ body: registrarEntradaBodySchema }),
  registrarEntrada,
);

/**
 * @openapi
 * /tickets/{id}/salida:
 *   post:
 *     summary: Registrar la salida de un vehículo (operación transaccional)
 *     tags: [Tickets]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               metodo: { type: string, enum: [EFECTIVO, TARJETA, TRANSFERENCIA] }
 *               valorManual: { type: integer, minimum: 0 }
 *     responses:
 *       200:
 *         description: Ticket cerrado con el valor ya calculado, su desglose y el recibo listo para imprimir
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere OPERADOR)
 *       404:
 *         description: Ticket no encontrado
 *       409:
 *         description: El ticket ya no está abierto o el operador no tiene turno abierto
 *       422:
 *         description: Falta el método de pago o el valor manual (vehículo OTRO)
 */
ticketRouter.post(
  '/:id/salida',
  auth,
  authorize('OPERADOR'),
  validate({ params: idParamSchema, body: registrarSalidaBodySchema }),
  registrarSalida,
);

/**
 * @openapi
 * /tickets/{id}/anular:
 *   post:
 *     summary: Anular un ticket abierto, dejando registro de motivo y usuario
 *     tags: [Tickets]
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
 *             required: [motivo]
 *             properties:
 *               motivo: { type: string, example: "Se registró la placa equivocada" }
 *     responses:
 *       200:
 *         description: Ticket anulado, celda liberada
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Ticket no encontrado
 *       409:
 *         description: El ticket ya no está abierto
 */
ticketRouter.post(
  '/:id/anular',
  auth,
  authorize('ADMIN'),
  validate({ params: idParamSchema, body: anularTicketBodySchema }),
  anularTicket,
);

/**
 * @openapi
 * /tickets/{id}/entregar:
 *   post:
 *     summary: Marcar un ticket pagado como entregado al propietario
 *     tags: [Tickets]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Ticket entregado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN u OPERADOR)
 *       404:
 *         description: Ticket no encontrado
 *       409:
 *         description: El ticket no está pagado
 */
ticketRouter.post(
  '/:id/entregar',
  auth,
  authorize('ADMIN', 'OPERADOR'),
  validate({ params: idParamSchema }),
  entregarTicket,
);
