import { logger } from '../config/logger.js';

// process.hrtime.bigint() no se afecta por ajustes al reloj del sistema,
// a diferencia de Date.now(): una medición de duración no debe poder
// alterarse por un cambio de hora del SO.
export function requestTiming(req, res, next) {
  const inicio = process.hrtime.bigint();

  res.on('finish', () => {
    const duracionMs = Number(process.hrtime.bigint() - inicio) / 1e6;
    const endpoint = req.route ? `${req.baseUrl}${req.route.path}` : req.originalUrl;

    logger.info({
      method: req.method,
      endpoint,
      statusCode: res.statusCode,
      duracionMs: Math.round(duracionMs * 100) / 100,
    });
  });

  next();
}
