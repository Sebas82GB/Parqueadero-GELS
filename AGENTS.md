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

## Grafo de conocimiento (graphify)

Cada proyecto tiene el suyo, en su propia carpeta. **No hay grafo en la raiz y no debe crearse**: backend (JS) y app (Dart) no comparten imports, asi que un grafo unificado seria dos islas sin una sola arista entre ellas.

| Proyecto | Grafo | Tamano |
| --- | --- | --- |
| `parqueadero-api` | `parqueadero-api/graphify-out/` | ~587 nodos |
| `parqueadero_app` | `parqueadero_app/graphify-out/` | ~2848 nodos |

**Regla de oro: actualiza antes de confiar.** Un grafo desactualizado no da error, da una respuesta incompleta que parece valida: responde "no existe" sobre un archivo que si existe. Antes de la primera consulta de una sesion, dentro del proyecto:

```bash
cd parqueadero-api        # o parqueadero_app
graphify update .         # AST local, sin LLM
```

Si una consulta devuelve algo inesperado o vacio, **sospecha del grafo antes que del codigo**.

### Que comando usar (de mas barato a mas caro)

Ejecuta siempre desde la carpeta del proyecto. En PowerShell es `graphify`, sin barra inicial.

| Comando | Coste | Cuando |
| --- | --- | --- |
| `graphify path "A" "B"` | ~2 lineas | Como se conectan dos cosas |
| `graphify explain "archivo.js"` | ~30 lineas | **El mas util.** Un archivo: que importa y quien lo importa, con linea exacta |
| `graphify query "..." --budget 600` | ~22 lineas | Solo si no sabes por que archivo empezar |
| `graphify query "..."` | ~62 lineas | Evitalo: satura el contexto sin ser mas preciso |

Prefiere **`explain` sobre un archivo concreto** antes que `query`. Las preguntas amplias devuelven cientos de nodos truncados y mezclan fixtures de test irrelevantes; `--depth` no los acota (se ignora), solo `--budget` recorta, y recortar ruido no lo vuelve senal.

### Para que sirve en esta cadena

- **Alcance real de una fase.** `explain` sobre lo que vas a tocar lista sus dependientes. Es lo que dice si una fase cabe en 6 archivos *antes* de planearla en detalle.
- **Auditar la arquitectura por capas.** Si un `*.controller.js` importa un `*.repository.js` directamente, el grafo lo ensena: se salto `service`.
- **Encontrar el precedente completo.** Para replicar un patron, `explain` sobre la entidad modelo devuelve su cadena de archivos de una vez.

**Quien lo usa:** el coordinador para medir alcance, el refinador para localizar precedente y dependientes. **El implementador no lo usa**: recibe archivos ya decididos y explorar contradice su alcance literal.

**Lo que no hace:** da estructura (que importa a que), no logica de negocio. Para saber *por que* un ticket se anula en vez de borrarse, sigue siendo el `CLAUDE.md` y el servicio. El grafo no sustituye leer el codigo, solo te dice que leer.

Tras `git pull` el grafo queda desfasado: usa `git gpull` (alias configurado) o ejecuta `graphify update .` a mano.

## Lo que debe mantenerse sincronizado

Cuando algo cambia en el backend, revisa en la app: DTO/modelo del feature, `switch` de enums, manejo de `code` en el notifier, repositorio del feature, `API_BASE_URL`/`CORS_ORIGINS`. Si detectas desalineación, avísala aunque no sea parte de la tarea.

## Entorno de desarrollo

Backend corriendo en `npm run dev` + `docker compose up -d` (http://localhost:3000). App Flutter en `flutter run -d chrome --web-port=5173 --dart-define=API_BASE_URL=http://localhost:3000/api/v1`. El puerto 5173 debe coincidir con `CORS_ORIGINS` del backend.
