# Graph Report - parqueadero-api  (2026-09-12)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 580 nodes · 1538 edges · 32 communities (27 shown, 3 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 55 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d155a62b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- ticket.routes.test.js
- ticket.repository.js
- package.json
- auth.service.js
- env.js
- UnprocessableEntityError
- celda.repository.js
- horario-operacion.routes.js
- turno.service.js
- NotFoundError
- routes/index.js
- ticket.routes.js
- mensualidad.repository.js
- mensualidad.routes.js
- tarifa.routes.js
- usuario.routes.js
- celda.routes.js
- ConflictError
- turno.repository.js
- seed.js
- turno.routes.js
- tarifa-calculo.service.js
- auth.routes.js
- errors/index.js
- refresh-token.repository.js
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
8. `createApp()` - 14 edges
9. `express` - 13 edges
10. `createUsuarioInDb()` - 12 edges

## Surprising Connections (you probably didn't know these)
- `ConflictError` --inherits--> `AppError`  [EXTRACTED]
  src/errors/conflict-error.js → src/errors/app-error.js
- `traducirErrorCodigoDuplicado()` --calls--> `ConflictError`  [EXTRACTED]
  src/repositories/celda.repository.js → src/errors/conflict-error.js
- `cerrar()` --calls--> `ConflictError`  [EXTRACTED]
  src/repositories/horario-operacion.repository.js → src/errors/conflict-error.js
- `cancelar()` --calls--> `ConflictError`  [EXTRACTED]
  src/repositories/mensualidad.repository.js → src/errors/conflict-error.js
- `pagarTransaccional()` --calls--> `ConflictError`  [EXTRACTED]
  src/repositories/mensualidad.repository.js → src/errors/conflict-error.js

## Import Cycles
- None detected.

## Communities (32 total, 3 thin omitted)

### Community 0 - "ticket.routes.test.js"
Cohesion: 0.09
Nodes (59): supertest, vitest, createApp(), prisma, cors(), errorHandler(), requestTiming(), buildCeldaPayload() (+51 more)

### Community 1 - "ticket.repository.js"
Cohesion: 0.07
Nodes (28): HorarioOperacion, toHoraDate(), toHoraString(), Pago, Tarifa, Ticket, Vehiculo, crearConAutoCierre() (+20 more)

### Community 2 - "package.json"
Cohesion: 0.04
Nodes (46): dependencies, bcryptjs, express, jsonwebtoken, pino, @prisma/client, swagger-jsdoc, swagger-ui-express (+38 more)

### Community 3 - "auth.service.js"
Cohesion: 0.10
Nodes (27): bcryptjs, UnauthorizedError, Usuario, buildWhere(), create(), findByEmail(), findById(), findMany() (+19 more)

### Community 4 - "env.js"
Cohesion: 0.13
Nodes (12): pino, env, envSchema, parsed, logger, getHealth(), pingDatabase(), app (+4 more)

### Community 5 - "UnprocessableEntityError"
Cohesion: 0.13
Nodes (17): UnprocessableEntityError, calcularTarifa(), mensualidadVigente(), previsualizarTarifa(), validarRango(), cerrarTarifa(), crearTarifa(), listarTarifas() (+9 more)

### Community 6 - "celda.repository.js"
Cohesion: 0.19
Nodes (14): Celda, buildWhere(), create(), findByCodigo(), findById(), findMany(), traducirErrorCodigoDuplicado(), update() (+6 more)

### Community 7 - "horario-operacion.routes.js"
Cohesion: 0.20
Nodes (12): cerrarHorario(), crearHorario(), listarHorarios(), obtenerHorarioPorId(), horarioOperacionRouter, cerrarHorario(), crearHorario(), listarHorarios() (+4 more)

### Community 8 - "turno.service.js"
Cohesion: 0.28
Nodes (13): ForbiddenError, abrirTurno(), armarArqueo(), calcularTotales(), cerrarTurno(), completarArqueo(), finVentanaAutomatica(), listarTurnos() (+5 more)

### Community 9 - "NotFoundError"
Cohesion: 0.21
Nodes (12): NotFoundError, anularTicket(), entregarTicket(), listarTickets(), obtenerTicketPorId(), registrarEntrada(), generarCodigoTicket(), buildTicket() (+4 more)

### Community 10 - "routes/index.js"
Cohesion: 0.17
Nodes (11): express, getEstablecimiento(), auth(), celdaRouter, establecimientoRouter, healthRouter, apiRouter, mensualidadRouter (+3 more)

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
Cohesion: 0.28
Nodes (11): cerrarTarifa(), crearTarifa(), listarTarifas(), obtenerTarifaPorId(), simularTarifa(), authorize(), crearTarifaBodySchema, idParamSchema (+3 more)

### Community 15 - "usuario.routes.js"
Cohesion: 0.27
Nodes (11): zod, actualizarUsuario(), crearUsuario(), listarUsuarios(), obtenerUsuarioPorId(), usuarioRouter, actualizarUsuarioBodySchema, crearUsuarioBodySchema (+3 more)

### Community 16 - "celda.routes.js"
Cohesion: 0.32
Nodes (11): actualizarCelda(), crearCelda(), listarCeldas(), marcarMantenimiento(), obtenerCeldaPorId(), volverALibre(), actualizarCeldaBodySchema, crearCeldaBodySchema (+3 more)

### Community 17 - "ConflictError"
Cohesion: 0.32
Nodes (8): ConflictError, upsertByPlaca(), actualizarMensualidad(), cancelarMensualidad(), crearMensualidad(), listarMensualidades(), obtenerMensualidadPorId(), pagarMensualidad()

### Community 18 - "turno.repository.js"
Cohesion: 0.30
Nodes (9): Turno, buildWhere(), cerrar(), completarArqueo(), create(), findAbiertoByOperador(), findById(), findMany() (+1 more)

### Community 19 - "seed.js"
Cohesion: 0.23
Nodes (12): HORARIO_VIGENTE, main(), MENSUALIDADES_EJEMPLO, seedCeldas(), seedHorarios(), seedMensualidades(), seedTarifas(), seedUsuarios() (+4 more)

### Community 20 - "turno.routes.js"
Cohesion: 0.33
Nodes (10): @prisma/client, abrirTurno(), cerrarTurno(), completarArqueo(), listarTurnos(), obtenerArqueo(), abrirTurnoBodySchema, cerrarTurnoBodySchema (+2 more)

### Community 21 - "tarifa-calculo.service.js"
Cohesion: 0.33
Nodes (11): aperturaInstant(), calcularBloques(), cierreInstant(), siguienteApertura(), BOGOTA_OFFSET_MS, bogotaInstant(), bogotaParts(), HORA_MS (+3 more)

### Community 22 - "auth.routes.js"
Cohesion: 0.38
Nodes (8): login(), logout(), me(), refresh(), authRouter, loginBodySchema, logoutBodySchema, refreshBodySchema

### Community 24 - "refresh-token.repository.js"
Cohesion: 0.39
Nodes (4): RefreshToken, create(), findByHash(), revoke()

### Community 25 - ".prettierrc.json"
Cohesion: 0.33
Nodes (5): printWidth, semi, singleQuote, tabWidth, trailingComma

### Community 26 - "validate.js"
Cohesion: 0.60
Nodes (3): ValidationError, parsePart(), validate()

### Community 27 - "horario-operacion.repository.js"
Cohesion: 0.70
Nodes (4): buildWhere(), cerrar(), findById(), findMany()

## Knowledge Gaps
- **82 isolated node(s):** `VALORES_POR_DEFECTO`, `VALORES_POR_TIPO`, `app`, `adminToken`, `app` (+77 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 125 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `vitest` connect `ticket.routes.test.js` to `package.json`, `auth.service.js`, `env.js`, `UnprocessableEntityError`, `celda.repository.js`, `horario-operacion.routes.js`, `turno.service.js`, `NotFoundError`, `ConflictError`?**
  _High betweenness centrality (0.123) - this node is a cross-community bridge._
- **Why does `@prisma/client` connect `turno.routes.js` to `ticket.routes.test.js`, `ticket.repository.js`, `package.json`, `auth.service.js`, `celda.repository.js`, `ticket.routes.js`, `mensualidad.routes.js`, `tarifa.routes.js`, `usuario.routes.js`, `celda.routes.js`, `ConflictError`?**
  _High betweenness centrality (0.085) - this node is a cross-community bridge._
- **Why does `ConflictError` connect `ConflictError` to `ticket.repository.js`, `auth.service.js`, `UnprocessableEntityError`, `celda.repository.js`, `turno.service.js`, `NotFoundError`, `mensualidad.repository.js`, `turno.repository.js`, `errors/index.js`, `horario-operacion.repository.js`?**
  _High betweenness centrality (0.072) - this node is a cross-community bridge._
- **What connects `VALORES_POR_DEFECTO`, `VALORES_POR_TIPO`, `app` to the rest of the system?**
  _82 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `ticket.routes.test.js` be split into smaller, more focused modules?**
  _Cohesion score 0.08727593300029386 - nodes in this community are weakly interconnected._
- **Should `ticket.repository.js` be split into smaller, more focused modules?**
  _Cohesion score 0.06857142857142857 - nodes in this community are weakly interconnected._
- **Should `package.json` be split into smaller, more focused modules?**
  _Cohesion score 0.04251700680272109 - nodes in this community are weakly interconnected._