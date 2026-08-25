import { env } from '../config/env.js';

const METODOS_PERMITIDOS = 'GET,POST,PATCH';
const HEADERS_PERMITIDOS = 'Content-Type,Authorization';

// Sin dependencia externa: allow-list explícita contra CORS_ORIGINS. Un
// origen no permitido simplemente no recibe los headers Access-Control-*,
// que es lo que hace que el navegador bloquee la respuesta (el servidor no
// puede "rechazar" un cross-origin request; solo puede no autorizarlo).
export function cors(req, res, next) {
  const origin = req.headers.origin;
  const permitido = Boolean(origin) && env.CORS_ORIGINS.includes(origin);

  if (permitido) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
    res.setHeader('Access-Control-Allow-Credentials', 'true');
  }

  if (req.method === 'OPTIONS') {
    if (permitido) {
      res.setHeader('Access-Control-Allow-Methods', METODOS_PERMITIDOS);
      res.setHeader('Access-Control-Allow-Headers', HEADERS_PERMITIDOS);
    }
    return res.status(204).end();
  }

  next();
}
