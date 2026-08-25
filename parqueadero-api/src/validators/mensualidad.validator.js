import { z } from 'zod';
import { TipoVehiculo, MetodoPago, EstadoPagoMensualidad } from '@prisma/client';

const tipoVehiculoSchema = z.nativeEnum(TipoVehiculo, {
  errorMap: () => ({
    message: `tipoVehiculo debe ser uno de: ${Object.values(TipoVehiculo).join(', ')}`,
  }),
});

export const idParamSchema = z.object({
  id: z.string().uuid('El id debe ser un UUID válido'),
});

export const crearMensualidadBodySchema = z
  .object({
    placa: z
      .string()
      .trim()
      .min(3, 'La placa debe tener al menos 3 caracteres')
      .max(10, 'La placa no puede superar 10 caracteres')
      .regex(/^[A-Za-z0-9-]+$/, 'La placa solo admite letras, números y guiones')
      .transform((v) => v.toUpperCase()),
    tipoVehiculo: tipoVehiculoSchema,
    propietarioNombre: z.string().trim().min(1).max(100).optional(),
    propietarioTelefono: z.string().trim().min(1).max(30).optional(),
    celdaId: z.string().uuid('celdaId debe ser un UUID válido').optional(),
    fechaInicio: z.coerce.date({ invalid_type_error: 'fechaInicio debe ser una fecha válida' }),
    fechaFin: z.coerce.date({ invalid_type_error: 'fechaFin debe ser una fecha válida' }),
    valorMensualidad: z.number().int('valorMensualidad debe ser un entero').positive(),
  })
  .strict()
  .refine((data) => data.fechaFin > data.fechaInicio, {
    message: 'fechaFin debe ser posterior a fechaInicio',
    path: ['fechaFin'],
  });

export const actualizarMensualidadBodySchema = z
  .object({
    celdaId: z.string().uuid('celdaId debe ser un UUID válido').optional(),
    fechaInicio: z.coerce.date({ invalid_type_error: 'fechaInicio debe ser una fecha válida' }).optional(),
    fechaFin: z.coerce.date({ invalid_type_error: 'fechaFin debe ser una fecha válida' }).optional(),
    valorMensualidad: z.number().int('valorMensualidad debe ser un entero').positive().optional(),
  })
  .strict()
  .refine((data) => Object.keys(data).length > 0, {
    message: 'Debe incluir al menos un campo para actualizar',
  })
  .refine(
    (data) =>
      data.fechaInicio === undefined || data.fechaFin === undefined || data.fechaFin > data.fechaInicio,
    { message: 'fechaFin debe ser posterior a fechaInicio', path: ['fechaFin'] },
  );

export const pagarMensualidadBodySchema = z
  .object({
    metodo: z.nativeEnum(MetodoPago, {
      errorMap: () => ({ message: `metodo debe ser uno de: ${Object.values(MetodoPago).join(', ')}` }),
    }),
  })
  .strict();

export const listarMensualidadesQuerySchema = z.object({
  estadoPago: z.nativeEnum(EstadoPagoMensualidad).optional(),
  placa: z
    .string()
    .trim()
    .min(1)
    .max(10)
    .transform((v) => v.toUpperCase())
    .optional(),
  vigencia: z.enum(['VIGENTE', 'POR_VENCER', 'VENCIDA']).optional(),
  diasPorVencer: z.coerce.number().int().positive().default(7),
  page: z.coerce.number().int().positive().default(1),
  perPage: z.coerce.number().int().positive().max(100, 'perPage no puede superar 100').default(20),
});
