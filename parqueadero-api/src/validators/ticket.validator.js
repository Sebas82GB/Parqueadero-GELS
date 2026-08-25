import { z } from 'zod';
import { TipoVehiculo, MetodoPago, EstadoTicket } from '@prisma/client';

const tipoVehiculoSchema = z.nativeEnum(TipoVehiculo, {
  errorMap: () => ({
    message: `tipoVehiculo debe ser uno de: ${Object.values(TipoVehiculo).join(', ')}`,
  }),
});

export const idParamSchema = z.object({
  id: z.string().uuid('El id debe ser un UUID válido'),
});

export const registrarEntradaBodySchema = z
  .object({
    placa: z
      .string()
      .trim()
      .min(3, 'La placa debe tener al menos 3 caracteres')
      .max(10, 'La placa no puede superar 10 caracteres')
      .regex(/^[A-Za-z0-9-]+$/, 'La placa solo admite letras, números y guiones')
      .transform((v) => v.toUpperCase()),
    tipoVehiculo: tipoVehiculoSchema,
    celdaId: z.string().uuid('celdaId debe ser un UUID válido'),
    propietarioNombre: z.string().trim().min(1).max(100).optional(),
    propietarioTelefono: z.string().trim().min(1).max(30).optional(),
  })
  .strict();

// Express 5 deja req.body === undefined en un POST sin cuerpo (a diferencia
// de Express 4), y la salida cubierta por mensualidad legítimamente no manda
// body — sin .default({}) esa llamada devolvería 400 en vez de 200.
export const registrarSalidaBodySchema = z
  .object({
    metodo: z.nativeEnum(MetodoPago).optional(),
    valorManual: z
      .number()
      .int('valorManual debe ser un entero')
      .nonnegative('valorManual no puede ser negativo')
      .max(10_000_000, 'valorManual es demasiado alto')
      .optional(),
  })
  .strict()
  .default({});

export const anularTicketBodySchema = z
  .object({
    motivo: z
      .string()
      .trim()
      .min(5, 'El motivo debe tener al menos 5 caracteres')
      .max(300, 'El motivo no puede superar 300 caracteres'),
  })
  .strict();

export const listarTicketsQuerySchema = z.object({
  estado: z.nativeEnum(EstadoTicket).optional(),
  vehiculoId: z.string().uuid().optional(),
  celdaId: z.string().uuid().optional(),
  placa: z
    .string()
    .trim()
    .min(1)
    .max(10)
    .transform((v) => v.toUpperCase())
    .optional(),
  desde: z.coerce.date({ invalid_type_error: 'desde debe ser una fecha válida' }).optional(),
  hasta: z.coerce.date({ invalid_type_error: 'hasta debe ser una fecha válida' }).optional(),
  page: z.coerce.number().int().positive().default(1),
  perPage: z.coerce.number().int().positive().max(100, 'perPage no puede superar 100').default(20),
});
