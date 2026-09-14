# AGENTS.md — parqueadero-api

<mark>Este `AGENTS.md` es el puente. Las reglas completas están en `CLAUDE.md` (este directorio). Léelo entero antes de tocar código.</mark>

> **OBLIGATORIO antes de tocar nada:** ejecuta `graphify update .` en este directorio (~14 s). Si PowerShell responde `El término 'graphify' no se reconoce`, el binario no está en el PATH: invócalo por ruta completa con `& "$env:USERPROFILE\.local\bin\graphify.exe" update .` (misma sintaxis para `explain`, `path` y `query`). Es la primera accion de la sesion, antes de leer codigo o planear. Un grafo desfasado no falla: responde "no existe" sobre archivos que si existen, y ese dato falso se propaga al refinador y al implementador. Detalle en el `AGENTS.md` de la raiz.

API REST de gestión de parqueadero: `Node.js 22` (ESM) + `Express 5` + `PostgreSQL 16` + `Prisma` + `Zod` + `JWT` + `Vitest`/`Supertest`.

## No negociable

- El flujo de capas es sagrado y no salta niveles: `route → middleware → controller → service → repository → Prisma → PostgreSQL` (model en el camino). Ver sección 3 del `CLAUDE.md`.
- El esquema de base de datos solo cambia con **migración Prisma**, nunca a mano.
- Errores de dominio (`NotFoundError`, `ConflictError`, …), sin `try/catch` en controladores.
- Contrato de la API en: `src/routes/*.routes.js` (anotaciones `@openapi`), `src/validators/*.validator.js` (Zod), `src/models/*.js` y `prisma/schema.prisma`. Nunca adivines un DTO.

## Verificación antes de entregar

```sh
npm run lint
npm test
```

Docker: `docker compose up -d` (Postgres dev `5432`, test `5433`).

## Relación con el otro proyecto

`parqueadero_app/` es **solo lectura** desde aquí: se puede consultar para conocer el contrato (DTOs, enums, `API_BASE_URL`/`CORS_ORIGINS`), pero no se modifica. Si un cambio lo exige, dilo y espera.
