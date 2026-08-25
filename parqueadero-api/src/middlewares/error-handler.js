import { AppError } from '../errors/index.js';
import { logger } from '../config/logger.js';

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        details: err.details,
      },
    });
  }

  logger.error({ err }, 'Unhandled error');

  return res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Ha ocurrido un error inesperado',
      details: [],
    },
  });
}
