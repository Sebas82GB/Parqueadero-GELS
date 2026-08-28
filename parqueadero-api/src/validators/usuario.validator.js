import { z } from 'zod';
import { Rol } from '@prisma/client';

const rolSchema = z.nativeEnum(Rol, {
  errorMap: () => ({ message: `rol debe ser uno de: ${Object.values(Rol).join(', ')}` }),
});

export const idParamSchema = z.object({
  id: z.string().uuid('El id debe ser un UUID válido'),
});

export const crearUsuarioBodySchema = z
  .object({
    nombre: z.string().trim().min(1, 'El nombre es obligatorio').max(100),
    email: z.string().trim().toLowerCase().email('El email no es válido'),
    password: z.string().min(8, 'La contraseña debe tener al menos 8 caracteres'),
    rol: rolSchema,
  })
  .strict();

export const actualizarUsuarioBodySchema = z
  .object({
    nombre: z.string().trim().min(1).max(100).optional(),
    email: z.string().trim().toLowerCase().email('El email no es válido').optional(),
    password: z.string().min(8, 'La contraseña debe tener al menos 8 caracteres').optional(),
    rol: rolSchema.optional(),
    activo: z.boolean().optional(),
    baseInicialTurno: z
      .number()
      .int('baseInicialTurno debe ser un entero')
      .nonnegative('baseInicialTurno no puede ser negativo')
      .nullable()
      .optional(),
  })
  .strict()
  .refine((data) => Object.keys(data).length > 0, {
    message: 'Debe incluir al menos un campo para actualizar',
  });

export const listarUsuariosQuerySchema = z.object({
  rol: rolSchema.optional(),
  // z.coerce.boolean() coacciona cualquier string no vacío a `true`
  // (incluido "false"), así que el booleano de query string se parsea a mano.
  activo: z
    .enum(['true', 'false'], { errorMap: () => ({ message: 'activo debe ser "true" o "false"' }) })
    .transform((v) => v === 'true')
    .optional(),
  page: z.coerce.number().int().positive().default(1),
  perPage: z.coerce.number().int().positive().max(100, 'perPage no puede superar 100').default(20),
});
