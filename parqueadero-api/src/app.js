import express from 'express';
import swaggerUi from 'swagger-ui-express';
import { apiRouter } from './routes/index.js';
import { cors } from './middlewares/cors.js';
import { errorHandler } from './middlewares/error-handler.js';
import { openapiSpec } from './config/openapi.js';

export function createApp() {
  const app = express();

  app.use(cors);
  app.use(express.json());
  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(openapiSpec));
  app.use('/api/v1', apiRouter);
  app.use(errorHandler);

  return app;
}
