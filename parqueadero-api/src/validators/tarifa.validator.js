import { z } from 'zod';
import { TipoVehiculo } from '@prisma/client';

const tipoVehiculoSchema = z.nativeEnum(TipoVehiculo, {
  errorMap: () => ({
    message: `tipoVehiculo debe ser uno de: ${Object.values(TipoVehiculo).join(', ')}`,
  }),
});

export const idParamSchema = z.object({
  id: z.string().uuid('El id debe ser un UUID válido'),
});

export const crearTarifaBodySchema = z
  .object({
    tipoVehiculo: tipoVehiculoSchema,
    valorMinuto: z.number().int('valorMinuto debe ser un entero').nonnegative(),
    valorPlena: z.number().int('valorPlena debe ser un entero').nonnegative(),
    valorNocturna: z.number().int('valorNocturna debe ser un entero').nonnegative(),
    valorMes: z.number().int('valorMes debe ser un entero').nonnegative(),
  })
  .strict();

export const simularTarifaBodySchema = z
  .object({
    tipoVehiculo: tipoVehiculoSchema,
    valorMinuto: z.number().int('valorMinuto debe ser un entero').nonnegative(),
    valorPlena: z.number().int('valorPlena debe ser un entero').nonnegative(),
    valorNocturna: z.number().int('valorNocturna debe ser un entero').nonnegative(),
    duracionMinutos: z
      .number()
      .int('duracionMinutos debe ser un entero')
      .positive('duracionMinutos debe ser mayor a 0'),
    horaEntrada: z.coerce
      .date({ invalid_type_error: 'horaEntrada debe ser una fecha válida' })
      .optional(),
  })
  .strict();

export const actualizarTarifaBodySchema = z
  .object({
    valorMinuto: z.number().int('valorMinuto debe ser un entero').nonnegative().optional(),
    valorPlena: z.number().int('valorPlena debe ser un entero').nonnegative().optional(),
    valorNocturna: z.number().int('valorNocturna debe ser un entero').nonnegative().optional(),
    valorMes: z.number().int('valorMes debe ser un entero').nonnegative().optional(),
  })
  .strict()
  .refine((data) => Object.keys(data).length > 0, {
    message: 'Debe incluir al menos un campo para actualizar',
  });

export const listarTarifasQuerySchema = z.object({
  tipoVehiculo: tipoVehiculoSchema.optional(),
  // z.coerce.boolean() no sirve acá: Boolean("false") === true, así que
  // "?vigente=false" coercería a true. Se compara el string explícitamente.
  vigente: z
    .enum(['true', 'false'], { errorMap: () => ({ message: 'vigente debe ser true o false' }) })
    .optional()
    .transform((v) => (v === undefined ? undefined : v === 'true')),
  page: z.coerce.number().int().positive().default(1),
  perPage: z.coerce.number().int().positive().max(100, 'perPage no puede superar 100').default(20),
});
