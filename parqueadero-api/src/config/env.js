import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),

  // Lista de orígenes separados por coma admitidos por el middleware CORS.
  // Sin default explícito (var ausente) equivale a "" -> allow-list vacía:
  // ningún origen cross-origin queda habilitado hasta que se configure.
  CORS_ORIGINS: z
    .string()
    .default('')
    .transform((value) =>
      value
        .split(',')
        .map((origin) => origin.trim())
        .filter(Boolean),
    ),

  DATABASE_URL: z.string().url(),

  JWT_ACCESS_SECRET: z.string().min(1, 'JWT_ACCESS_SECRET no puede estar vacío'),
  JWT_REFRESH_SECRET: z.string().min(1, 'JWT_REFRESH_SECRET no puede estar vacío'),
  JWT_ACCESS_EXPIRES_IN: z.string().min(1),
  JWT_REFRESH_EXPIRES_IN: z.string().min(1),

  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),

  // Datos del establecimiento para el recibo de salida y GET /establecimiento.
  // Sin default: si falta alguno, el proceso falla al arrancar (mismo
  // criterio que los secretos JWT).
  ESTABLECIMIENTO_NOMBRE: z.string().min(1, 'ESTABLECIMIENTO_NOMBRE no puede estar vacío'),
  ESTABLECIMIENTO_NIT: z.string().min(1, 'ESTABLECIMIENTO_NIT no puede estar vacío'),
  ESTABLECIMIENTO_DIRECCION: z.string().min(1, 'ESTABLECIMIENTO_DIRECCION no puede estar vacío'),
  ESTABLECIMIENTO_TELEFONO: z.string().min(1, 'ESTABLECIMIENTO_TELEFONO no puede estar vacío'),
  ESTABLECIMIENTO_CIUDAD: z.string().min(1, 'ESTABLECIMIENTO_CIUDAD no puede estar vacío'),
  ESTABLECIMIENTO_REGIMEN_TRIBUTARIO: z
    .string()
    .min(1, 'ESTABLECIMIENTO_REGIMEN_TRIBUTARIO no puede estar vacío'),
  ESTABLECIMIENTO_NUMERO_RESOLUCION: z
    .string()
    .min(1, 'ESTABLECIMIENTO_NUMERO_RESOLUCION no puede estar vacío'),
  ESTABLECIMIENTO_TEXTO_RESPONSABILIDAD: z
    .string()
    .min(1, 'ESTABLECIMIENTO_TEXTO_RESPONSABILIDAD no puede estar vacío'),
  ESTABLECIMIENTO_TEXTO_SEGURO: z
    .string()
    .min(1, 'ESTABLECIMIENTO_TEXTO_SEGURO no puede estar vacío'),
  ESTABLECIMIENTO_TEXTO_HORARIO: z
    .string()
    .min(1, 'ESTABLECIMIENTO_TEXTO_HORARIO no puede estar vacío'),
  ESTABLECIMIENTO_TEXTO_RECLAMOS: z
    .string()
    .min(1, 'ESTABLECIMIENTO_TEXTO_RECLAMOS no puede estar vacío'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  const details = parsed.error.issues
    .map((issue) => `  - ${issue.path.join('.')}: ${issue.message}`)
    .join('\n');
  console.error(`Configuración de entorno inválida:\n${details}`);
  process.exit(1);
}

export const env = parsed.data;
