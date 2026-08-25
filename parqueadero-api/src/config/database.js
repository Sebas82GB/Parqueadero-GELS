import { PrismaClient } from '@prisma/client';

// Singleton: evita abrir múltiples pools de conexión bajo `node --watch`
// (cada reinicio del proceso reutiliza este módulo si no se limpia el registro).
export const prisma = globalThis.__prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== 'production') {
  globalThis.__prisma = prisma;
}
