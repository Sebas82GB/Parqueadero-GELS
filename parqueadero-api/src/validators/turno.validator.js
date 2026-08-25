import { z } from 'zod';
import { EstadoTurno } from '@prisma/client';

export const idParamSchema = z.object({
  id: z.string().uuid('El id debe ser un UUID válido'),
});

export const abrirTurnoBodySchema = z
  .object({
    baseInicial: z
      .number()
      .int('baseInicial debe ser un entero')
      .nonnegative('baseInicial no puede ser negativo'),
  })
  .strict();

export const cerrarTurnoBodySchema = z
  .object({
    efectivoContado: z
      .number()
      .int('efectivoContado debe ser un entero')
      .nonnegative('efectivoContado no puede ser negativo'),
  })
  .strict();

export const listarTurnosQuerySchema = z.object({
  operadorId: z.string().uuid().optional(),
  estado: z.nativeEnum(EstadoTurno).optional(),
  desde: z.coerce.date({ invalid_type_error: 'desde debe ser una fecha válida' }).optional(),
  hasta: z.coerce.date({ invalid_type_error: 'hasta debe ser una fecha válida' }).optional(),
  page: z.coerce.number().int().positive().default(1),
  perPage: z.coerce.number().int().positive().max(100, 'perPage no puede superar 100').default(20),
});
