import { Router } from 'express';
import { auth } from '../middlewares/auth.js';
import { authorize } from '../middlewares/authorize.js';
import { validate } from '../middlewares/validate.js';
import {
  idParamSchema,
  crearUsuarioBodySchema,
  actualizarUsuarioBodySchema,
  listarUsuariosQuerySchema,
} from '../validators/usuario.validator.js';
import {
  listarUsuarios,
  obtenerUsuarioPorId,
  crearUsuario,
  actualizarUsuario,
} from '../controllers/usuario.controller.js';

export const usuarioRouter = Router();

/**
 * @openapi
 * /usuarios:
 *   get:
 *     summary: Listar usuarios
 *     tags: [Usuarios]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: rol
 *         schema: { type: string, enum: [ADMIN, OPERADOR] }
 *       - in: query
 *         name: activo
 *         schema: { type: string, enum: ['true', 'false'] }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: perPage
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: Lista paginada de usuarios
 *       400:
 *         description: Parámetros de filtro o paginación inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 */
usuarioRouter.get(
  '/',
  auth,
  authorize('ADMIN'),
  validate({ query: listarUsuariosQuerySchema }),
  listarUsuarios,
);

/**
 * @openapi
 * /usuarios/{id}:
 *   get:
 *     summary: Obtener un usuario por id
 *     tags: [Usuarios]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: Usuario encontrado
 *       400:
 *         description: Id inválido
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Usuario no encontrado
 */
usuarioRouter.get(
  '/:id',
  auth,
  authorize('ADMIN'),
  validate({ params: idParamSchema }),
  obtenerUsuarioPorId,
);

/**
 * @openapi
 * /usuarios:
 *   post:
 *     summary: Crear un usuario
 *     tags: [Usuarios]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [nombre, email, password, rol]
 *             properties:
 *               nombre: { type: string }
 *               email: { type: string, format: email }
 *               password: { type: string, format: password, minLength: 8 }
 *               rol: { type: string, enum: [ADMIN, OPERADOR] }
 *     responses:
 *       201:
 *         description: Usuario creado
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       409:
 *         description: Email duplicado
 */
usuarioRouter.post(
  '/',
  auth,
  authorize('ADMIN'),
  validate({ body: crearUsuarioBodySchema }),
  crearUsuario,
);

/**
 * @openapi
 * /usuarios/{id}:
 *   patch:
 *     summary: Actualizar un usuario (incluye activar/desactivar y configurar baseInicialTurno)
 *     tags: [Usuarios]
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
 *               nombre: { type: string }
 *               email: { type: string, format: email }
 *               password: { type: string, format: password, minLength: 8 }
 *               rol: { type: string, enum: [ADMIN, OPERADOR] }
 *               activo: { type: boolean }
 *               baseInicialTurno:
 *                 type: integer
 *                 minimum: 0
 *                 nullable: true
 *                 description: >
 *                   Solo tiene efecto en un ADMIN: la baseInicial fija que usa el turno automático al abrir
 *                   un turno sin que el operador la digite. Se usa la del ADMIN activo más antiguo que la
 *                   tenga configurada.
 *     responses:
 *       200:
 *         description: Usuario actualizado
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: Sin permisos (requiere ADMIN)
 *       404:
 *         description: Usuario no encontrado
 *       409:
 *         description: Email duplicado
 */
usuarioRouter.patch(
  '/:id',
  auth,
  authorize('ADMIN'),
  validate({ params: idParamSchema, body: actualizarUsuarioBodySchema }),
  actualizarUsuario,
);
