import { execSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const rootDir = path.resolve(fileURLToPath(import.meta.url), '../../..');

// Corre una sola vez, antes de toda la suite de integración: carga
// .env.test en este proceso y aplica las migraciones contra la BD de test
// (nunca la de desarrollo) antes de que arranque ningún test.
export async function setup() {
  process.loadEnvFile(path.join(rootDir, '.env.test'));

  execSync('prisma migrate deploy', {
    cwd: rootDir,
    env: process.env,
    stdio: 'inherit',
  });
}
