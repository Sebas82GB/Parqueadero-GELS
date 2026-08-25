import { Router } from 'express';
import { auth } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import {
  loginBodySchema,
  refreshBodySchema,
  logoutBodySchema,
} from '../validators/auth.validator.js';
import { login, refresh, logout, me } from '../controllers/auth.controller.js';

export const authRouter = Router();

/**
 * @openapi
 * /auth/login:
 *   post:
 *     summary: Iniciar sesión
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email: { type: string, format: email }
 *               password: { type: string, format: password }
 *     responses:
 *       200:
 *         description: Login exitoso, devuelve el usuario y el par de tokens
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: Credenciales inválidas (email inexistente, password incorrecta o usuario inactivo)
 */
authRouter.post('/login', validate({ body: loginBodySchema }), login);

/**
 * @openapi
 * /auth/refresh:
 *   post:
 *     summary: Rotar el refresh token y obtener un nuevo par de tokens
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [refreshToken]
 *             properties:
 *               refreshToken: { type: string }
 *     responses:
 *       200:
 *         description: Nuevo par de tokens
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: Refresh token inválido, expirado, revocado o de un usuario inactivo
 */
authRouter.post('/refresh', validate({ body: refreshBodySchema }), refresh);

/**
 * @openapi
 * /auth/logout:
 *   post:
 *     summary: Invalidar un refresh token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [refreshToken]
 *             properties:
 *               refreshToken: { type: string }
 *     responses:
 *       204:
 *         description: Refresh token invalidado (idempotente si ya lo estaba)
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: El refreshToken no es un JWT válido
 */
authRouter.post('/logout', validate({ body: logoutBodySchema }), logout);

/**
 * @openapi
 * /auth/me:
 *   get:
 *     summary: Datos del usuario autenticado
 *     tags: [Auth]
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200:
 *         description: Usuario autenticado
 *       401:
 *         description: No autenticado
 */
authRouter.get('/me', auth, me);
