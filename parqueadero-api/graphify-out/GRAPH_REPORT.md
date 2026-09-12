# Graph Report - parqueadero-api  (2026-09-12)

## Corpus Check
- 135 files · ~45,918 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 587 nodes · 1585 edges · 27 communities (23 shown, 2 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 55 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `639b859d`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- ticket.routes.test.js
- ticket.repository.js
- package.json
- auth.service.js
- auth.js
- errors/index.js
- AGENTS.md — parqueadero-api
- horario-operacion.routes.js
- ConflictError
- routes/index.js
- ticket.routes.js
- mensualidad.repository.js
- mensualidad.routes.js
- tarifa.routes.js
- usuario.routes.js
- celda.routes.js
- turno.repository.js
- seed.js
- turno.routes.js
- auth.routes.js
- .prettierrc.json
- validate.js
- horario-operacion.repository.js
- global-setup.js
- setup.js

## God Nodes (most connected - your core abstractions)
1. `ConflictError` - 53 edges
2. `NotFoundError` - 35 edges
3. `prisma` - 26 edges
4. `vitest` - 22 edges
5. `UnprocessableEntityError` - 17 edges
6. `AppError` - 16 edges
7. `resetOperacion()` - 16 edges
8. `toSkipTake()` - 15 edges
9. `sendPage()` - 15 edges
10. `createApp()` - 14 edges

## Surprising Connections (you probably didn't know these)
- `createApp()` --indirect_call--> `cors()`  [INFERRED]
  src/app.js → src/middlewares/cors.js
- `createApp()` --indirect_call--> `errorHandler()`  [INFERRED]
  src/app.js → src/middlewares/error-handler.js
- `createApp()` --indirect_call--> `requestTiming()`  [INFERRED]
  src/app.js → src/middlewares/request-timing.js
- `listarCeldas()` --calls--> `sendPage()`  [EXTRACTED]
  src/controllers/celda.controller.js → src/utils/paginacion.util.js
- `listarHorarios()` --calls--> `sendPage()`  [EXTRACTED]
  src/controllers/horario-operacion.controller.js → src/utils/paginacion.util.js

## Import Cycles
- None detected.

## Communities (27 total, 2 thin omitted)

### Community 0 - "ticket.routes.test.js"
Cohesion: 0.09
Nodes (59): supertest, vitest, createApp(), prisma, cors(), errorHandler(), requestTiming(), buildCeldaPayload() (+51 more)

### Community 1 - "ticket.repository.js"
Cohesion: 0.08
Nodes (30): Celda, Pago, Ticket, Usuario, buildWhere(), create(), findByCodigo(), findById() (+22 more)

### Community 2 - "package.json"
Cohesion: 0.04
Nodes (46): dependencies, bcryptjs, express, jsonwebtoken, pino, @prisma/client, swagger-jsdoc, swagger-ui-express (+38 more)

### Community 3 - "auth.service.js"
Cohesion: 0.12
Nodes (23): bcryptjs, UnauthorizedError, RefreshToken, create(), findByHash(), revoke(), credencialesInvalidas(), DUMMY_HASH (+15 more)

### Community 4 - "auth.js"
Cohesion: 0.11
Nodes (13): pino, env, envSchema, parsed, logger, getEstablecimiento(), getHealth(), pingDatabase() (+5 more)

### Community 5 - "errors/index.js"
Cohesion: 0.08
Nodes (39): AppError, ForbiddenError, UnprocessableEntityError, aperturaInstant(), calcularBloques(), calcularTarifa(), cierreInstant(), mensualidadVigente() (+31 more)

### Community 6 - "AGENTS.md — parqueadero-api"
Cohesion: 0.40
Nodes (4): AGENTS.md — parqueadero-api, No negociable, Relación con el otro proyecto, Verificación antes de entregar

### Community 7 - "horario-operacion.routes.js"
Cohesion: 0.31
Nodes (8): cerrarHorario(), crearHorario(), listarHorarios(), obtenerHorarioPorId(), authorize(), crearHorarioBodySchema, idParamSchema, listarHorariosQuerySchema

### Community 9 - "ConflictError"
Cohesion: 0.08
Nodes (39): ConflictError, NotFoundError, Tarifa, Vehiculo, buildWhere(), cerrar(), crearConAutoCierre(), findById() (+31 more)

### Community 10 - "routes/index.js"
Cohesion: 0.16
Nodes (12): express, auth(), authRouter, celdaRouter, establecimientoRouter, horarioOperacionRouter, apiRouter, mensualidadRouter (+4 more)

### Community 11 - "ticket.routes.js"
Cohesion: 0.28
Nodes (13): anularTicket(), entregarTicket(), listarTickets(), obtenerTicketPorId(), previsualizarCobro(), registrarEntrada(), registrarSalida(), anularTicketBodySchema (+5 more)

### Community 12 - "mensualidad.repository.js"
Cohesion: 0.26
Nodes (10): Mensualidad, buildWhere(), cancelar(), create(), findById(), findMany(), findVigenteByCelda(), findVigenteByVehiculo() (+2 more)

### Community 13 - "mensualidad.routes.js"
Cohesion: 0.30
Nodes (12): actualizarMensualidad(), cancelarMensualidad(), crearMensualidad(), listarMensualidades(), obtenerMensualidadPorId(), pagarMensualidad(), actualizarMensualidadBodySchema, crearMensualidadBodySchema (+4 more)

### Community 14 - "tarifa.routes.js"
Cohesion: 0.33
Nodes (10): cerrarTarifa(), crearTarifa(), listarTarifas(), obtenerTarifaPorId(), simularTarifa(), crearTarifaBodySchema, idParamSchema, listarTarifasQuerySchema (+2 more)

### Community 15 - "usuario.routes.js"
Cohesion: 0.32
Nodes (10): actualizarUsuario(), crearUsuario(), listarUsuarios(), obtenerUsuarioPorId(), sendPage(), actualizarUsuarioBodySchema, crearUsuarioBodySchema, idParamSchema (+2 more)

### Community 16 - "celda.routes.js"
Cohesion: 0.32
Nodes (11): actualizarCelda(), crearCelda(), listarCeldas(), marcarMantenimiento(), obtenerCeldaPorId(), volverALibre(), actualizarCeldaBodySchema, crearCeldaBodySchema (+3 more)

### Community 18 - "turno.repository.js"
Cohesion: 0.30
Nodes (9): Turno, buildWhere(), cerrar(), completarArqueo(), create(), findAbiertoByOperador(), findById(), findMany() (+1 more)

### Community 19 - "seed.js"
Cohesion: 0.23
Nodes (12): HORARIO_VIGENTE, main(), MENSUALIDADES_EJEMPLO, seedCeldas(), seedHorarios(), seedMensualidades(), seedTarifas(), seedUsuarios() (+4 more)

### Community 20 - "turno.routes.js"
Cohesion: 0.33
Nodes (10): @prisma/client, abrirTurno(), cerrarTurno(), completarArqueo(), listarTurnos(), obtenerArqueo(), abrirTurnoBodySchema, cerrarTurnoBodySchema (+2 more)

### Community 22 - "auth.routes.js"
Cohesion: 0.38
Nodes (8): zod, login(), logout(), me(), refresh(), loginBodySchema, logoutBodySchema, refreshBodySchema

### Community 25 - ".prettierrc.json"
Cohesion: 0.33
Nodes (5): printWidth, semi, singleQuote, tabWidth, trailingComma

### Community 26 - "validate.js"
Cohesion: 0.60
Nodes (3): ValidationError, parsePart(), validate()

### Community 27 - "horario-operacion.repository.js"
Cohesion: 0.17
Nodes (13): HorarioOperacion, toHoraDate(), toHoraString(), buildWhere(), cerrar(), crearConAutoCierre(), findById(), findMany() (+5 more)

## Knowledge Gaps
- **84 isolated node(s):** `semi`, `singleQuote`, `trailingComma`, `printWidth`, `tabWidth` (+79 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 128 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `vitest` connect `ticket.routes.test.js` to `package.json`, `auth.service.js`, `auth.js`, `errors/index.js`, `ConflictError`, `horario-operacion.repository.js`?**
  _High betweenness centrality (0.119) - this node is a cross-community bridge._
- **Why does `@prisma/client` connect `turno.routes.js` to `ticket.routes.test.js`, `ticket.repository.js`, `package.json`, `ConflictError`, `ticket.routes.js`, `mensualidad.routes.js`, `tarifa.routes.js`, `usuario.routes.js`, `celda.routes.js`?**
  _High betweenness centrality (0.082) - this node is a cross-community bridge._
- **Why does `prisma` connect `ticket.routes.test.js` to `ticket.repository.js`, `auth.service.js`, `auth.js`, `errors/index.js`, `ConflictError`, `mensualidad.repository.js`, `turno.repository.js`, `seed.js`, `horario-operacion.repository.js`?**
  _High betweenness centrality (0.069) - this node is a cross-community bridge._
- **What connects `semi`, `singleQuote`, `trailingComma` to the rest of the system?**
  _84 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `ticket.routes.test.js` be split into smaller, more focused modules?**
  _Cohesion score 0.09272151898734177 - nodes in this community are weakly interconnected._
- **Should `ticket.repository.js` be split into smaller, more focused modules?**
  _Cohesion score 0.08069381598793364 - nodes in this community are weakly interconnected._
- **Should `package.json` be split into smaller, more focused modules?**
  _Cohesion score 0.04251700680272109 - nodes in this community are weakly interconnected._