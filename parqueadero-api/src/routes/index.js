import { Router } from 'express';
import { healthRouter } from './health.routes.js';
import { celdaRouter } from './celda.routes.js';
import { authRouter } from './auth.routes.js';
import { usuarioRouter } from './usuario.routes.js';
import { turnoRouter } from './turno.routes.js';
import { ticketRouter } from './ticket.routes.js';
import { tarifaRouter } from './tarifa.routes.js';
import { horarioOperacionRouter } from './horario-operacion.routes.js';
import { mensualidadRouter } from './mensualidad.routes.js';
import { establecimientoRouter } from './establecimiento.routes.js';

export const apiRouter = Router();

apiRouter.use(healthRouter);
apiRouter.use('/celdas', celdaRouter);
apiRouter.use('/auth', authRouter);
apiRouter.use('/usuarios', usuarioRouter);
apiRouter.use('/turnos', turnoRouter);
apiRouter.use('/tickets', ticketRouter);
apiRouter.use('/tarifas', tarifaRouter);
apiRouter.use('/horarios', horarioOperacionRouter);
apiRouter.use('/mensualidades', mensualidadRouter);
apiRouter.use('/establecimiento', establecimientoRouter);
