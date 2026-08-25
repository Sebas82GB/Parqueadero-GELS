import { pingDatabase } from '../repositories/health.repository.js';

export async function checkHealth() {
  try {
    await pingDatabase();
    return { status: 'ok', database: 'up' };
  } catch {
    return { status: 'ok', database: 'disconnected' };
  }
}
