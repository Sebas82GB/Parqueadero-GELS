import { z } from 'zod';

export const loginBodySchema = z
  .object({
    email: z.string().trim().email('El email no es válido'),
    password: z.string().min(1, 'La contraseña es obligatoria'),
  })
  .strict();

export const refreshBodySchema = z
  .object({
    refreshToken: z.string().min(1, 'El refreshToken es obligatorio'),
  })
  .strict();

export const logoutBodySchema = refreshBodySchema;
