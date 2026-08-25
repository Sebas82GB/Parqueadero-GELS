import { ValidationError } from '../errors/index.js';

function parsePart(req, key, schema) {
  const result = schema.safeParse(req[key]);

  if (!result.success) {
    const details = result.error.issues.map((issue) => ({
      field: issue.path.join('.'),
      message: issue.message,
    }));
    throw new ValidationError('Datos de entrada inválidos', 'VALIDATION_ERROR', details);
  }

  if (key === 'query') {
    // req.query es una propiedad solo-getter en Express 5; hay que
    // reemplazarla en vez de asignarla directamente.
    Object.defineProperty(req, 'query', {
      value: result.data,
      writable: true,
      configurable: true,
      enumerable: true,
    });
  } else {
    req[key] = result.data;
  }
}

export function validate(schemas) {
  return function validateMiddleware(req, res, next) {
    for (const key of ['params', 'query', 'body']) {
      if (schemas[key]) {
        parsePart(req, key, schemas[key]);
      }
    }
    next();
  };
}
