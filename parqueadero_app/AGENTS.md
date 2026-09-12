# AGENTS.md — parqueadero_app

<mark>Este `AGENTS.md` es el puente. Las reglas completas están en `CLAUDE.md` (este directorio). Léelo entero antes de tocar código.</mark>

> **OBLIGATORIO antes de tocar nada:** ejecuta `graphify update .` en este directorio (~36 s). Es la primera accion de la sesion, antes de leer codigo o planear. Un grafo desfasado no falla: responde "no existe" sobre archivos que si existen, y ese dato falso se propaga al refinador y al implementador. Detalle en el `AGENTS.md` de la raiz.

Cliente Flutter para la API de parqueadero. Plataforma actual: **web (Chrome)**; Android/iOS después (no cerrar esa puerta). Feature-first en 3 capas (presentación → dominio → datos). Aplicación operada de pie: objetivos táctiles grandes, poca escritura, confirmaciones claras.

## No negociable

- **Este proyecto no tiene lógica de negocio**: tarifas, disponibilidad y reglas de estado las resuelve el backend. La app muestra resultados y presenta errores tal como llegan.
- `switch` de enums: todo enum del dominio Flutter que espeje un enum del backend debe considerar todos sus valores (no asumir solo los que hoy se usan).
- El sistema de diseño de la app vive en la skill **`diseno-parqueadero`** (`.opencode/skills/diseno-parqueadero/SKILL.md`). Cárgala antes de tocar UI.
- Los repositorios consumen la API según el contrato real del backend: consulta `parqueadero-api/src/routes/*.routes.js`, `src/validators/*.validator.js` y `src/models/*.js` — nunca adivines la forma de un DTO.

## Verificación antes de entregar

```sh
flutter analyze
flutter test
```

## Relación con el otro proyecto

`parqueadero-api/` es **solo lectura** desde aquí: se puede consultar para conocer el contrato, pero no se modifica. Si un cambio ahí lo exige, dilo y espera.
