import { createApp } from './app.js';
import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { checkHealth } from './services/health.service.js';

const app = createApp();

app.listen(env.PORT, async () => {
  logger.info(`Servidor escuchando en http://localhost:${env.PORT}`);

  const health = await checkHealth();
  if (health.database === 'disconnected') {
    logger.warn(
      'El servidor arrancó sin conexión a la base de datos. Las rutas que dependan de Postgres fallarán hasta que la conexión se restablezca.',
    );
  }
});
