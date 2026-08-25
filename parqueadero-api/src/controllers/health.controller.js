import { checkHealth } from '../services/health.service.js';

export async function getHealth(req, res) {
  const result = await checkHealth();
  res.status(200).json(result);
}
