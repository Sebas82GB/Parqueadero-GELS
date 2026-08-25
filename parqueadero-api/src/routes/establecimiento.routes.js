import { Router } from 'express';
import { auth } from '../middlewares/auth.js';
import { getEstablecimiento } from '../controllers/establecimiento.controller.js';

export const establecimientoRouter = Router();

/**
 * @openapi
 * /establecimiento:
 *   get:
 *     summary: Obtener los datos del establecimiento (para encabezado/pie del recibo)
 *     tags: [Establecimiento]
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200:
 *         description: Datos del establecimiento
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Establecimiento'
 *       401:
 *         description: No autenticado
 */
establecimientoRouter.get('/', auth, getEstablecimiento);
