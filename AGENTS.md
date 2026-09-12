# AGENTS.md — Raíz del espacio de trabajo

<mark>El CLAUDE.md de la raíz es la autoridad. Este archivo es solo el puente para los agentes.</mark>

Este directorio contiene **dos proyectos independientes** que forman un solo sistema. Cada uno tiene su propio `CLAUDE.md`, su propio `AGENTS.md` y (en principio) su propio repositorio git.

```
parqueadero-api/    API REST — Node.js 22 + Express 5 + Prisma + PostgreSQL
parqueadero_app/    Cliente Flutter (web por ahora, móvil después)
```

**Antes de trabajar en cualquiera de los dos, lee su `CLAUDE.md` propio.**

## Regla: una tarea pertenece a UN proyecto

El otro es material de solo lectura, útil para conocer el contrato entre ambos.

- **Trabajando en `parqueadero_app/`** → puedes leer `parqueadero-api/`, pero **no modificas nada del backend**. Si hace falta un cambio allá, dilo y espera.
- **Trabajando en `parqueadero-api/`** → igual en sentido contrario.
- Si una tarea de verdad exige tocar los dos, propón el plan y espera aprobación antes de escribir en ninguno.

Si detectas una contradicción entre lo que ves y estos archivos, **repórtala**: no la resuelvas silenciosamente.

## Dónde está el contrato de la API

Nunca adivines la forma de un DTO. Consulta, en orden:

1. `parqueadero-api/src/routes/*.routes.js` — anotaciones `@openapi` de cada endpoint.
2. `parqueadero-api/src/validators/*.validator.js` — esquemas Zod.
3. `parqueadero-api/src/models/*.js` — entidades de dominio serializadas.
4. `parqueadero-api/prisma/schema.prisma` — enums y restricciones.

## Lo que debe mantenerse sincronizado

Cuando algo cambia en el backend, revisa en la app: DTO/modelo del feature, `switch` de enums, manejo de `code` en el notifier, repositorio del feature, `API_BASE_URL`/`CORS_ORIGINS`. Si detectas desalineación, avísala aunque no sea parte de la tarea.

## Entorno de desarrollo

Backend corriendo en `npm run dev` + `docker compose up -d` (http://localhost:3000). App Flutter en `flutter run -d chrome --web-port=5173 --dart-define=API_BASE_URL=http://localhost:3000/api/v1`. El puerto 5173 debe coincidir con `CORS_ORIGINS` del backend.