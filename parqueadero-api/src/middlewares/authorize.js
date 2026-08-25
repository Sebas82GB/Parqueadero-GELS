import { ForbiddenError } from '../errors/index.js';

export function authorize(...rolesPermitidos) {
  return function authorizeMiddleware(req, res, next) {
    if (!rolesPermitidos.includes(req.user?.rol)) {
      throw new ForbiddenError('No tiene permisos para realizar esta acción');
    }
    next();
  };
}
