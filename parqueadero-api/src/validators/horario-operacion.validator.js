import { z } from 'zod';

const HORA_REGEX = /^([01]\d|2[0-3]):([0-5]\d)$/;
const horaLocalSchema = (campo) =>
  z.string().regex(HORA_REGEX, `${campo} debe tener formato HH:mm (24 horas)`);

export const idParamSchema = z.object({
  id: z.string().uuid('El id debe ser un UUID válido'),
});

export const crearHorarioBodySchema = z
  .object({
    apertura: horaLocalSchema('apertura'),
    cierre: horaLocalSchema('cierre'),
  })
  .strict()
  .refine((data) => data.cierre > data.apertura, {
    message: 'cierre debe ser posterior a apertura',
    path: ['cierre'],
  });

export const listarHorariosQuerySchema = z.object({
  // z.coerce.boolean() no sirve acá: Boolean("false") === true, así que
  // "?vigente=false" coercería a true. Se compara el string explícitamente.
  vigente: z
    .enum(['true', 'false'], { errorMap: () => ({ message: 'vigente debe ser true o false' }) })
    .optional()
    .transform((v) => (v === undefined ? undefined : v === 'true')),
  page: z.coerce.number().int().positive().default(1),
  perPage: z.coerce.number().int().positive().max(100, 'perPage no puede superar 100').default(20),
});
