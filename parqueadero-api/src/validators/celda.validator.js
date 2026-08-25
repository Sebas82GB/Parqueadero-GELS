import { z } from 'zod';
import { TipoVehiculo, EstadoCelda } from '@prisma/client';

const tipoPermitidoSchema = z.nativeEnum(TipoVehiculo, {
  errorMap: () => ({
    message: `tipoPermitido debe ser uno de: ${Object.values(TipoVehiculo).join(', ')}`,
  }),
});

export const idParamSchema = z.object({
  id: z.string().uuid('El id debe ser un UUID válido'),
});

export const crearCeldaBodySchema = z
  .object({
    codigo: z
      .string()
      .trim()
      .min(1, 'El código es obligatorio')
      .max(20, 'El código no puede superar 20 caracteres')
      .transform((v) => v.toUpperCase()),
    zona: z
      .string()
      .trim()
      .min(1, 'La zona es obligatoria')
      .max(100, 'La zona no puede superar 100 caracteres'),
    tipoPermitido: tipoPermitidoSchema,
  })
  .strict();

export const actualizarCeldaBodySchema = crearCeldaBodySchema
  .partial()
  .refine((data) => Object.keys(data).length > 0, {
    message: 'Debe incluir al menos un campo para actualizar',
  });

export const listarCeldasQuerySchema = z.object({
  zona: z.string().trim().min(1).optional(),
  estado: z.nativeEnum(EstadoCelda).optional(),
  tipoPermitido: tipoPermitidoSchema.optional(),
  page: z.coerce.number().int().positive().default(1),
  perPage: z.coerce.number().int().positive().max(100, 'perPage no puede superar 100').default(20),
});
