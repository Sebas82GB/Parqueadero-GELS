import { fileURLToPath } from 'node:url';
import path from 'node:path';

const rootDir = path.resolve(fileURLToPath(import.meta.url), '../../..');

// A diferencia de globalSetup, esto corre en el mismo proceso/contexto que
// cada archivo de test, así que es lo que realmente garantiza que
// config/database.js vea la DATABASE_URL de test antes de construir el
// PrismaClient. No debe asumirse ninguna variable ya cargada por fuera
// (el script npm de integración no pasa --env-file=.env a propósito) para
// que .env.test sea siempre la única fuente y nunca compita con .env.
process.loadEnvFile(path.join(rootDir, '.env.test'));
