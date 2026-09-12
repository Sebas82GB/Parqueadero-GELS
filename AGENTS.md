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

### OBLIGATORIO al iniciar sesion

**La primera accion de toda sesion de desarrollo es actualizar el grafo del proyecto de la tarea.** No es opcional ni queda a criterio: va antes de leer codigo, antes de planear y antes de cualquier consulta al grafo.

```bash
cd parqueadero-api        # si la tarea es del backend   (~14 s)
graphify update .         # AST local, sin LLM, sin coste de tokens

cd parqueadero_app        # si la tarea es de la app     (~36 s)
graphify update .
```

Actualiza **solo el proyecto de la tarea**: una tarea pertenece a UN proyecto, y actualizar el otro es tiempo perdido. Si la sesion cambia de proyecto a medias, actualiza el nuevo antes de consultarlo.

**Por que es obligatorio.** Un grafo desactualizado no da error: da una respuesta incompleta que parece valida. Responde "no existe" sobre un archivo que si existe. Ha pasado dos veces en este repo:

- `paginacion.util.js` estaba commiteado y el grafo respondia "No node matching found".
- Los widgets `admin_home_dashboard.dart`, `dashboard_metric_card.dart` y `dashboard_action_group.dart` estaban ausentes del grafo del front despues de commitearlos.

En los dos casos el codigo estaba bien y el grafo mentia. Si esa respuesta entra a un plan, se propaga al refinador y al implementador como un hecho falso: una fase se dimensiona mal, o se declara que algo no tiene dependientes cuando tiene catorce.

Si una consulta devuelve algo inesperado o vacio **despues** de actualizar, entonces si: sospecha del codigo. Antes de actualizar, sospecha siempre del grafo.

Excepcion unica: si la sesion no va a tocar codigo (configuracion, documentacion, dudas conceptuales), no hace falta. En cuanto aparezca la primera pregunta sobre estructura del codigo, actualiza primero.


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

## Skills de ingenieria (agent-skills)

Cuatro skills de `addyosmani/agent-skills` (MIT) instalados en `~/.config/opencode/skills/`, disponibles en los dos proyectos. Se eligieron **solo los que cubren huecos** de esta cadena: no se instalo el pack completo porque sus skills de spec/plan/build duplican lo que ya hacen coordinador, refinador e implementador.

| Skill | Cuando | Quien |
| --- | --- | --- |
| `code-review-and-quality` | Revisar un diff antes de dar por buena una fase | coordinador |
| `security-and-hardening` | Entrada de usuario, auth, datos sensibles, dependencias | coordinador al planear, refinador al enumerar tests |
| `debugging-and-error-recovery` | Un test falla, algo se rompe, comportamiento inesperado | cualquiera |
| `code-simplification` | El codigo funciona pero cuesta leerlo | coordinador al revisar |

Se invocan con la herramienta `skill` cuando la situacion aplica. **No hay activacion automatica a proposito**: el pack oficial propone un intent-mapping que invoca skills antes de actuar, y eso desplazaria la cadena coordinador -> refinador -> implementador. Aqui la cadena manda y el skill es una consulta puntual.

**PRECEDENCIA (regla dura):** si un skill choca con el `CLAUDE.md` del proyecto o con el flujo de esta cadena, **manda el `CLAUDE.md`**. Casos concretos que van a ocurrir:

- `code-review-and-quality` sugiere cambios de ~100 lineas. La regla de aqui son fases de hasta 6 archivos con aprobacion humana. Gana la fase.
- Varios skills piden crear documentos propios (PRD, `CONSTRAINTS.md`). **No se crean**: la autoridad es el `CLAUDE.md` que ya existe, y dos fuentes de reglas compitiendo es peor que una.
- Si un skill propone saltarse una capa o abstraer "por si acaso", pierde: mandan la arquitectura por capas y YAGNI.

Los skills no sustituyen la puerta de aprobacion. Un hallazgo de `code-review-and-quality` o `security-and-hardening` se reporta al humano; no autoriza a ampliar el alcance de una fase en curso.

## Lo que debe mantenerse sincronizado

Cuando algo cambia en el backend, revisa en la app: DTO/modelo del feature, `switch` de enums, manejo de `code` en el notifier, repositorio del feature, `API_BASE_URL`/`CORS_ORIGINS`. Si detectas desalineación, avísala aunque no sea parte de la tarea.

## Entorno de desarrollo

Backend corriendo en `npm run dev` + `docker compose up -d` (http://localhost:3000). App Flutter en `flutter run -d chrome --web-port=5173 --dart-define=API_BASE_URL=http://localhost:3000/api/v1`. El puerto 5173 debe coincidir con `CORS_ORIGINS` del backend.
