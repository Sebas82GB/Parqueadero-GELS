# Graph Report - parqueadero_app  (2026-09-12)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 2848 nodes · 5045 edges · 172 communities (168 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d155a62b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- turno_cierre_notifier_test.dart
- usuario_detail_screen.dart
- mensualidades_screen_test.dart
- package:parqueadero_app/core/network/api_exception.dart
- app_router.dart
- package:parqueadero_app/features/auth/domain/usuario.dart
- package:go_router/go_router.dart
- package:flutter_riverpod/flutter_riverpod.dart
- buscar_placa_screen_test.dart
- registrar_salida_screen.dart
- _
- MockAuthRepository
- mensualidad_repository_test.dart
- Mock
- sessionNotifierProvider
- celda_list_notifier_test.dart
- celda_card.dart
- recibo_dto.dart
- turno_cierre_screen.dart
- ticket.dart
- ticket_dto.dart
- celda_list_state.dart
- ../../../core/utils/bogota_time.dart
- horario_repository_impl.dart
- operador_home_dashboard.dart
- turnos_historial_screen_test.dart
- Notifier
- celdas_screen_test.dart
- nueva_tarifa_screen.dart
- recibo.dart
- tarifa_repository_impl.dart
- nuevo_horario_screen.dart
- ConsumerState
- Dio
- ticket_repository_test.dart
- StatelessWidget
- empty_state.dart
- status_style_test.dart
- nueva_mensualidad_screen.dart
- registrar_entrada_screen.dart
- pago.dart
- package:parqueadero_app/features/auth/data/auth_repository_impl.dart
- celda_accion_rapida_sheet.dart
- _
- loading_skeleton.dart
- tarifa.dart
- horario_repository_test.dart
- mensualidad.dart
- ticket_list_state.dart
- arqueo_turno_dto.dart
- salida_notifier_test.dart
- registrar_salida_screen_test.dart
- usuario_dto.dart
- ticket_detail_screen_test.dart
- buscar_placa_screen.dart
- celda_repository_impl.dart
- package:dio/dio.dart
- package:flutter/material.dart
- registrar_entrada_screen_test.dart
- desglose_item.dart
- arqueo_turno.dart
- turno.dart
- vehiculo.dart
- mensualidad_repository_impl.dart
- celdas_screen.dart
- turno_cierre_screen_test.dart
- turno_cierre_notifier.dart
- @JsonSerializable
- celda_list_notifier.dart
- login_screen.dart
- refresh_interceptor_test.dart
- ../domain/ticket.dart
- List
- turno_dto.dart
- abrir_turno_screen.dart
- ../../../core/network/api_exception.dart
- ticket_repository.dart
- nuevo_usuario_screen.dart
- DateTime
- usuario_list_notifier.dart
- usuario.dart
- turno_repository.dart
- usuario_list_state.dart
- celda_accion_notifier.dart
- mensualidad_filtros_bar.dart
- celda.dart
- mensualidad_dto.dart
- mensualidad_list_state.dart
- tarifa_dto.dart
- pago_dto.dart
- ticket_list_notifier.dart
- turno_list_notifier.dart
- turno_list_state.dart
- operador_home_dashboard_test.dart
- celda_card_test.dart
- celda_accion_rapida_sheet_test.dart
- mensualidadListNotifierProvider
- mensualidad_list_notifier.dart
- turno_filtros_bar.dart
- turno_activo_indicator.dart
- celda_detail_screen_test.dart
- nueva_mensualidad_screen_test.dart
- celda_detail_screen.dart
- ../domain/celda.dart
- session_notifier.dart
- turno_cierre_state.dart
- turno_repository_impl.dart
- vehiculo_dto.dart
- horario.dart
- home_screen_test.dart
- api_client.dart
- usuario_repository.dart
- dart:async
- token_storage.dart
- tiempo_transcurrido_text.dart
- celda_dto.dart
- horario_dto.dart
- mensualidad_repository.dart
- tarifa_grupo_card.dart
- arqueo_summary_view.dart
- cobro_preview_notifier_test.dart
- recibo_screen_test.dart
- manifest.json
- usuario_page_dto.dart
- registrar_entrada_notifier.dart
- refresh_interceptor.dart
- nueva_mensualidad_notifier.dart
- recibo_view.dart
- salida_notifier.dart
- horario_page_dto.dart
- String?
- tarifa_page_dto.dart
- ticket_page_dto.dart
- turno_page_dto.dart
- nueva_tarifa_notifier.dart
- validators.dart
- tarifaListNotifierProvider
- turno_detail_notifier.dart
- _
- _
- _
- login_controller.dart
- _
- animated_count_text.dart
- tarifa_list_notifier.dart
- tarifa_list_state.dart
- cobro_preview_state.dart
- package:flutter_test/flutter_test.dart
- package:mocktail/mocktail.dart
- ../domain/turno.dart
- _
- static const
- package:json_annotation/json_annotation.dart
- vigencia_chip.dart
- turno_estado_chip.dart
- tarifa_accion_notifier.dart
- _
- _
- NuevaMensualidadNotifier
- NuevaTarifaNotifier
- ticket_abierto_de_celda_state.dart
- ../../domain/desglose_item.dart
- elapsed_time.dart
- upper_case_text_formatter.dart
- tarifa_accion_state.dart
- abrir_turno_state.dart
- build
- print_launcher_web.dart
- rol_usuario_label.dart
- RefreshInterceptor
- print_launcher.dart
- print_launcher_stub.dart

## God Nodes (most connected - your core abstractions)
1. `sessionNotifierProvider` - 44 edges
2. `AuthRepository` - 32 edges
3. `TicketRepository` - 25 edges
4. `_` - 23 edges
5. `celdaListNotifierProvider` - 22 edges
6. `TurnoRepository` - 18 edges
7. `CeldaRepository` - 15 edges
8. `_` - 12 edges
9. `_` - 12 edges
10. `_` - 12 edges

## Surprising Connections (you probably didn't know these)
- `MockAuthRepository` --implements--> `AuthRepository`  [EXTRACTED]
  test/unit/turno_cierre_notifier_test.dart → lib/features/auth/domain/auth_repository.dart
- `MockAuthRepository` --implements--> `AuthRepository`  [EXTRACTED]
  test/widget/abrir_turno_screen_test.dart → lib/features/auth/domain/auth_repository.dart
- `MockAuthRepository` --implements--> `AuthRepository`  [EXTRACTED]
  test/widget/turno_detail_screen_test.dart → lib/features/auth/domain/auth_repository.dart
- `MockAuthRepository` --implements--> `AuthRepository`  [EXTRACTED]
  test/widget/celda_detail_screen_test.dart → lib/features/auth/domain/auth_repository.dart
- `MockCeldaRepository` --implements--> `CeldaRepository`  [EXTRACTED]
  test/widget/celda_detail_screen_test.dart → lib/features/celdas/domain/celda_repository.dart

## Import Cycles
- None detected.

## Communities (172 total, 4 thin omitted)

### Community 0 - "turno_cierre_notifier_test.dart"
Cohesion: 0.05
Nodes (48): MockTurnoRepository, package:parqueadero_app/features/turnos/data/turno_repository_impl.dart, package:parqueadero_app/features/turnos/domain/arqueo_turno.dart, package:parqueadero_app/features/turnos/domain/turno.dart, package:parqueadero_app/features/turnos/domain/turno_repository.dart, package:parqueadero_app/features/turnos/presentation/abrir_turno_screen.dart, package:parqueadero_app/features/turnos/presentation/turno_cierre_notifier.dart, package:parqueadero_app/features/turnos/presentation/turno_cierre_state.dart (+40 more)

### Community 1 - "usuario_detail_screen.dart"
Cohesion: 0.05
Nodes (43): ../../auth/domain/usuario.dart, ../../../core/utils/rol_usuario_label.dart, ../../../../core/widgets/filtros_bar.dart, ../data/usuario_repository_impl.dart, build, crear, NuevoUsuarioNotifier, NuevoUsuarioState (+35 more)

### Community 2 - "mensualidades_screen_test.dart"
Cohesion: 0.06
Nodes (41): Hero, MockMensualidadRepository, package:parqueadero_app/features/mensualidades/data/mensualidad_repository_impl.dart, package:parqueadero_app/features/mensualidades/domain/mensualidad.dart, package:parqueadero_app/features/mensualidades/domain/mensualidad_repository.dart, package:parqueadero_app/features/mensualidades/presentation/mensualidad_accion_notifier.dart, package:parqueadero_app/features/mensualidades/presentation/mensualidad_detail_screen.dart, package:parqueadero_app/features/mensualidades/presentation/mensualidad_list_notifier.dart (+33 more)

### Community 3 - "package:parqueadero_app/core/network/api_exception.dart"
Cohesion: 0.06
Nodes (41): MockTarifaRepository, package:parqueadero_app/core/domain/tipo_vehiculo.dart, package:parqueadero_app/core/network/api_exception.dart, package:parqueadero_app/features/tarifas/data/tarifa_repository_impl.dart, package:parqueadero_app/features/tarifas/domain/tarifa.dart, package:parqueadero_app/features/tarifas/domain/tarifa_repository.dart, package:parqueadero_app/features/tarifas/presentation/nueva_tarifa_notifier.dart, package:parqueadero_app/features/tarifas/presentation/nueva_tarifa_screen.dart (+33 more)

### Community 4 - "app_router.dart"
Cohesion: 0.05
Nodes (42): ChangeNotifier, core/config/app_config.dart, core/router/app_router.dart, core/theme/app_theme.dart, ../../features/auth/presentation/home_screen.dart, ../../features/auth/presentation/login_screen.dart, ../../features/auth/presentation/session_notifier.dart, ../../features/auth/presentation/session_state.dart (+34 more)

### Community 5 - "package:parqueadero_app/features/auth/domain/usuario.dart"
Cohesion: 0.07
Nodes (36): MockUsuarioRepository, package:parqueadero_app/core/widgets/acceso_restringido.dart, package:parqueadero_app/features/auth/domain/usuario.dart, package:parqueadero_app/features/usuarios/data/usuario_repository_impl.dart, package:parqueadero_app/features/usuarios/domain/usuario_repository.dart, package:parqueadero_app/features/usuarios/presentation/nuevo_usuario_notifier.dart, package:parqueadero_app/features/usuarios/presentation/nuevo_usuario_screen.dart, package:parqueadero_app/features/usuarios/presentation/usuario_detail_notifier.dart (+28 more)

### Community 6 - "package:go_router/go_router.dart"
Cohesion: 0.08
Nodes (32): ../../auth/presentation/session_notifier.dart, ../../../core/theme/app_spacing.dart, ../../../core/widgets/acceso_restringido.dart, ../../../core/widgets/empty_state.dart, ../../../core/widgets/error_state.dart, ../domain/usuario.dart, _rolLabel, Horario (+24 more)

### Community 7 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.06
Nodes (34): MockHorarioRepository, package:flutter_riverpod/flutter_riverpod.dart, package:parqueadero_app/features/celdas/presentation/reloj_notifier.dart, package:parqueadero_app/features/horarios/domain/horario.dart, package:parqueadero_app/features/horarios/domain/horario_repository.dart, package:parqueadero_app/features/horarios/presentation/horario_list_notifier.dart, package:parqueadero_app/features/horarios/presentation/horarios_screen.dart, package:parqueadero_app/features/horarios/presentation/nuevo_horario_notifier.dart (+26 more)

### Community 8 - "buscar_placa_screen_test.dart"
Cohesion: 0.07
Nodes (34): MockTicketRepository, package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart, package:parqueadero_app/features/tickets/domain/ticket.dart, package:parqueadero_app/features/tickets/domain/ticket_repository.dart, package:parqueadero_app/features/tickets/presentation/buscar_placa_notifier.dart, package:parqueadero_app/features/tickets/presentation/buscar_placa_screen.dart, package:parqueadero_app/features/tickets/presentation/ticket_detail_notifier.dart, package:parqueadero_app/features/tickets/presentation/ticket_list_notifier.dart (+26 more)

### Community 9 - "registrar_salida_screen.dart"
Cohesion: 0.08
Nodes (34): cobro_preview_notifier.dart, ../../../core/utils/print/print_launcher.dart, ../../../core/widgets/detail_skeleton.dart, ../../../core/widgets/tiempo_transcurrido_text.dart, build, cobroPreviewNotifierProvider, build, ReciboScreen (+26 more)

### Community 10 - "_"
Cohesion: 0.07
Nodes (37): Color, ../../../core/theme/status_style.dart, IconData, _, color, icon, of, StatusStyle (+29 more)

### Community 11 - "MockAuthRepository"
Cohesion: 0.06
Nodes (33): MockAuthRepository, package:parqueadero_app/features/auth/domain/auth_repository.dart, package:parqueadero_app/features/auth/presentation/login_screen.dart, package:parqueadero_app/features/auth/presentation/session_notifier.dart, package:parqueadero_app/features/auth/presentation/session_state.dart, package:parqueadero_app/features/turnos/presentation/abrir_turno_notifier.dart, package:parqueadero_app/features/turnos/presentation/turno_activo_notifier.dart, authRepository (+25 more)

### Community 12 - "mensualidad_repository_test.dart"
Cohesion: 0.06
Nodes (33): DioExceptionType, Exception, ApiErrorDetail, ApiException, AppException, code, details, field (+25 more)

### Community 13 - "Mock"
Cohesion: 0.11
Nodes (34): TicketRepository, TurnoRepository, UsuarioRepository, Mock, MockTurnoRepository, MockTicketRepository, MockTicketRepository, MockUsuarioRepository (+26 more)

### Community 14 - "sessionNotifierProvider"
Cohesion: 0.12
Nodes (31): ConsumerWidget, HomeScreen, sessionNotifierProvider, OperadorHomeDashboard, celdaAccionNotifierProvider, build, CeldaDetailScreen, celdaListNotifierProvider (+23 more)

### Community 15 - "celda_list_notifier_test.dart"
Cohesion: 0.07
Nodes (29): MockCeldaRepository, package:parqueadero_app/features/celdas/domain/celda_repository.dart, package:parqueadero_app/features/celdas/presentation/celda_accion_notifier.dart, package:parqueadero_app/features/celdas/presentation/celda_list_notifier.dart, package:parqueadero_app/features/tickets/presentation/registrar_entrada_notifier.dart, celda, celdaRepository, container (+21 more)

### Community 16 - "celda_card.dart"
Cohesion: 0.07
Nodes (28): app_motion.dart, celda_accion_rapida_sheet.dart, celda_quick_actions_sheet.dart, ../../../../core/theme/app_elevation.dart, ../../../core/theme/app_radius.dart, ../../../../core/utils/haptics.dart, ../../../core/widgets/loading_skeleton.dart, CustomPainter (+20 more)

### Community 17 - "recibo_dto.dart"
Cohesion: 0.06
Nodes (29): desglose_item_dto.dart, ../domain/cobro_preview.dart, cobroPreviewFromJson, celda, ciudad, consecutivo, desglose, direccion (+21 more)

### Community 18 - "turno_cierre_screen.dart"
Cohesion: 0.08
Nodes (29): build, build, turnoCierreNotifierProvider, build, _completandoArqueo, _confirmarYCerrar, _contadoController, _contadoValidator (+21 more)

### Community 19 - "ticket.dart"
Cohesion: 0.07
Nodes (29): abierto,
  pagado,
  entregado,, anulado, anuladoEn, anuladoPorId, celda, celdaId, codigo, createdAt (+21 more)

### Community 20 - "ticket_dto.dart"
Cohesion: 0.07
Nodes (29): ../../../celdas/data/dtos/celda_dto.dart, anuladoEn, anuladoPorId, celda, celdaId, codigo, createdAt, desglose (+21 more)

### Community 21 - "celda_list_state.dart"
Cohesion: 0.07
Nodes (28): busquedaFiltro, celdas, celdasFiltradas, celdasFiltradasPorZona, compute, copyWith, _Derivados, errorMessage (+20 more)

### Community 22 - "../../../core/utils/bogota_time.dart"
Cohesion: 0.08
Nodes (24): ../../../core/utils/bogota_time.dart, ../../../core/utils/money.dart, ../../../core/widgets/material_hero.dart, estado_pago_chip.dart, Mensualidad, build, mensualidad, MensualidadListItem (+16 more)

### Community 23 - "horario_repository_impl.dart"
Cohesion: 0.08
Nodes (24): ../data/horario_repository_impl.dart, ../domain/horario.dart, ../domain/horario_repository.dart, dtos/horario_dto.dart, dtos/horario_page_dto.dart, horario_list_notifier.dart, horario_list_state.dart, crear (+16 more)

### Community 24 - "operador_home_dashboard.dart"
Cohesion: 0.08
Nodes (25): ../../../core/theme/app_breakpoints.dart, ../../../core/theme/app_colors.dart, ../../../../core/theme/app_motion.dart, ../../../core/widgets/animated_count_text.dart, _AccionPrincipal, _AccionSecundaria, borde, _CeldasLibresCard (+17 more)

### Community 25 - "turnos_historial_screen_test.dart"
Cohesion: 0.08
Nodes (24): package:parqueadero_app/core/widgets/empty_state.dart, package:parqueadero_app/core/widgets/error_state.dart, package:parqueadero_app/features/tickets/presentation/tickets_historial_screen.dart, package:parqueadero_app/features/turnos/presentation/turnos_historial_screen.dart, package:parqueadero_app/features/usuarios/presentation/usuarios_screen.dart, main, MockTicketRepository, pumpHistorialScreen (+16 more)

### Community 26 - "Notifier"
Cohesion: 0.09
Nodes (24): cobro_preview_state.dart, build, RelojNotifier, _timer, MensualidadListNotifier, ticketRepositoryProvider, buscar, BuscarPlacaNotifier (+16 more)

### Community 27 - "celdas_screen_test.dart"
Cohesion: 0.08
Nodes (23): AuthRepository, login, logout, restoreSession, package:parqueadero_app/core/widgets/animated_count_text.dart, package:parqueadero_app/features/celdas/presentation/celdas_screen.dart, package:parqueadero_app/features/celdas/presentation/widgets/celda_grid_skeleton.dart, MockAuthRepository (+15 more)

### Community 28 - "nueva_tarifa_screen.dart"
Cohesion: 0.09
Nodes (24): nuevaTarifaNotifierProvider, build, createState, _debounce, dispose, _duracionesPreset, duracionLabel, _duracionMinutos (+16 more)

### Community 29 - "recibo.dart"
Cohesion: 0.08
Nodes (24): celda, ciudad, consecutivo, desglose, direccion, Establecimiento, fechaEmision, horaEntrada (+16 more)

### Community 30 - "tarifa_repository_impl.dart"
Cohesion: 0.09
Nodes (22): ../domain/tarifa_repository.dart, dtos/tarifa_dto.dart, dtos/tarifa_page_dto.dart, cerrar, crear, _dio, listarTodas, _perPage (+14 more)

### Community 31 - "nuevo_horario_screen.dart"
Cohesion: 0.09
Nodes (23): nuevoHorarioNotifierProvider, _apertura, build, _cierre, createState, _elegirApertura, _elegirCierre, enabled (+15 more)

### Community 32 - "ConsumerState"
Cohesion: 0.12
Nodes (21): ConsumerState, ConsumerStatefulWidget, ../../../core/widgets/list_item_skeleton.dart, CeldaAccionRapidaSheet, _CeldaAccionRapidaSheetState, NuevaMensualidadScreen, ticketListNotifierProvider, build (+13 more)

### Community 33 - "Dio"
Cohesion: 0.09
Nodes (21): Dio, ../domain/usuario_repository.dart, dtos/usuario_page_dto.dart, actualizar, crear, _dio, listar, UsuarioRepositoryImpl (+13 more)

### Community 34 - "ticket_repository_test.dart"
Cohesion: 0.09
Nodes (21): ../domain/ticket_repository.dart, dtos/cobro_preview_dto.dart, dtos/ticket_dto.dart, dtos/ticket_page_dto.dart, _dio, listar, obtenerPorId, previsualizarCobro (+13 more)

### Community 35 - "StatelessWidget"
Cohesion: 0.09
Nodes (19): empty_state.dart, AccesoRestringido, build, build, ButtonSpinner, size, build, DetailSkeleton (+11 more)

### Community 36 - "empty_state.dart"
Cohesion: 0.09
Nodes (19): actionLabel, build, EmptyState, icon, message, onAction, build, error (+11 more)

### Community 37 - "status_style_test.dart"
Cohesion: 0.09
Nodes (20): BoxDecoration, Container, dart:math, package:parqueadero_app/core/theme/app_colors.dart, package:parqueadero_app/core/theme/status_style.dart, package:parqueadero_app/features/celdas/presentation/widgets/zona_header.dart, b, canal (+12 more)

### Community 38 - "nueva_mensualidad_screen.dart"
Cohesion: 0.09
Nodes (19): ../../celdas/domain/celda.dart, DateTimeRange?, formatBogota, toBogota, formatMoney, _celda, createState, dispose (+11 more)

### Community 39 - "registrar_entrada_screen.dart"
Cohesion: 0.10
Nodes (21): ../../celdas/presentation/widgets/celda_estado_badge.dart, registrarEntradaNotifierProvider, build, celdaId, createState, dispose, enabled, _formKey (+13 more)

### Community 40 - "pago.dart"
Cohesion: 0.09
Nodes (21): efectivo,
  tarjeta,, anulado, createdAt, estado, EstadoPago, fecha, fromBackend, hashCode (+13 more)

### Community 41 - "package:parqueadero_app/features/auth/data/auth_repository_impl.dart"
Cohesion: 0.09
Nodes (20): Icon, package:parqueadero_app/features/auth/data/auth_repository_impl.dart, package:parqueadero_app/features/turnos/presentation/widgets/turno_activo_indicator.dart, dio, _dioError, _jsonResponse, main, repository (+12 more)

### Community 42 - "celda_accion_rapida_sheet.dart"
Cohesion: 0.09
Nodes (21): _buscando, _buscar, celdaId, child, createState, dispose, esAncho, handle (+13 more)

### Community 43 - "_"
Cohesion: 0.10
Nodes (21): app_colors.dart, app_elevation.dart, app_page_transitions.dart, app_radius.dart, app_spacing.dart, _, AppTheme, _colorScheme (+13 more)

### Community 44 - "loading_skeleton.dart"
Cohesion: 0.11
Nodes (19): Animation, AnimationController, double?, borderRadius, build, _controller, createState, dispose (+11 more)

### Community 45 - "tarifa.dart"
Cohesion: 0.10
Nodes (18): ../../../core/domain/tipo_vehiculo.dart, createdAt, esVigente, hashCode, id, operator, tipoVehiculo, updatedAt (+10 more)

### Community 46 - "horario_repository_test.dart"
Cohesion: 0.10
Nodes (18): horario.dart, HorarioRepositoryImpl, crear, HorarioRepository, listarTodas, package:parqueadero_app/features/horarios/data/horario_repository_impl.dart, MockHorarioRepository, dio (+10 more)

### Community 47 - "mensualidad.dart"
Cohesion: 0.10
Nodes (19): cancelada, celdaId, createdAt, diasPorVencerDefault, estadoPago, fechaFin, fechaInicio, fechaPago (+11 more)

### Community 48 - "ticket_list_state.dart"
Cohesion: 0.10
Nodes (18): EstadoTicket, copyWith, desdeFiltro, errorMessage, estadoFiltro, hastaFiltro, hayMas, isLoading (+10 more)

### Community 49 - "arqueo_turno_dto.dart"
Cohesion: 0.10
Nodes (19): apertura, baseInicial, cierre, diferencia, efectivo, efectivoContado, efectivoEsperado, estado (+11 more)

### Community 50 - "salida_notifier_test.dart"
Cohesion: 0.11
Nodes (18): package:parqueadero_app/features/celdas/data/celda_repository_impl.dart, package:parqueadero_app/features/celdas/domain/celda.dart, package:parqueadero_app/features/tickets/presentation/salida_notifier.dart, package:parqueadero_app/features/tickets/presentation/salida_state.dart, _celdaJson, dio, _dioError, _jsonResponse (+10 more)

### Community 51 - "registrar_salida_screen_test.dart"
Cohesion: 0.10
Nodes (19): package:parqueadero_app/features/tickets/presentation/registrar_salida_screen.dart, Route /salida, authRepository, celda, celdaRepository, establecimiento, main, operador (+11 more)

### Community 52 - "usuario_dto.dart"
Cohesion: 0.11
Nodes (17): accessToken, fromJson, LoginResponseDto, refreshToken, usuario, activo, baseInicialTurno, createdAt (+9 more)

### Community 53 - "ticket_detail_screen_test.dart"
Cohesion: 0.11
Nodes (16): package:parqueadero_app/features/tickets/data/dtos/desglose_item_dto.dart, package:parqueadero_app/features/tickets/data/dtos/recibo_dto.dart, package:parqueadero_app/features/tickets/domain/desglose_item.dart, package:parqueadero_app/features/tickets/domain/pago.dart, package:parqueadero_app/features/tickets/domain/vehiculo.dart, package:parqueadero_app/features/tickets/presentation/ticket_detail_screen.dart, main, _establecimientoJson (+8 more)

### Community 54 - "buscar_placa_screen.dart"
Cohesion: 0.13
Nodes (17): buscar_placa_notifier.dart, ../../../core/utils/elapsed_time.dart, ../../../core/utils/upper_case_text_formatter.dart, buscarPlacaNotifierProvider, build, _buscar, BuscarPlacaScreen, _BuscarPlacaScreenState (+9 more)

### Community 55 - "celda_repository_impl.dart"
Cohesion: 0.12
Nodes (16): celda.dart, dtos/celda_dto.dart, dtos/celda_page_dto.dart, CeldaRepositoryImpl, _dio, listarTodas, marcarMantenimiento, _perPage (+8 more)

### Community 56 - "package:dio/dio.dart"
Cohesion: 0.12
Nodes (16): ../domain/auth_repository.dart, dtos/login_response_dto.dart, dtos/usuario_dto.dart, onRequest, _tokenStorage, AuthRepositoryImpl, _dio, login (+8 more)

### Community 57 - "package:flutter/material.dart"
Cohesion: 0.11
Nodes (14): ../domain/tipo_vehiculo.dart, tipoVehiculoIcon, tipoVehiculoLabel, build, child, MaterialHero, tag, build (+6 more)

### Community 58 - "registrar_entrada_screen_test.dart"
Cohesion: 0.11
Nodes (17): ElevatedButton, package:parqueadero_app/features/tickets/presentation/registrar_entrada_screen.dart, Route /entrada, authRepository, celdaLibre, celdaRepository, main, operador (+9 more)

### Community 59 - "desglose_item.dart"
Cohesion: 0.13
Nodes (17): bloqueNumero, DesgloseBloque, DesgloseItem, DesgloseManual, DesgloseMensualidad, dia, fin, fromBackend (+9 more)

### Community 60 - "arqueo_turno.dart"
Cohesion: 0.11
Nodes (17): apertura, baseInicial, cierre, diferencia, efectivo, efectivoContado, efectivoEsperado, estado (+9 more)

### Community 61 - "turno.dart"
Cohesion: 0.12
Nodes (16): abierto,
  cerradoPendienteArqueo,, apertura, baseInicial, cerrado, cierre, createdAt, diferencia, efectivoContado (+8 more)

### Community 62 - "vehiculo.dart"
Cohesion: 0.12
Nodes (15): carro,
  moto,
  bicicleta,, fromBackend, otro, TipoVehiculo, toBackend, createdAt, hashCode, id (+7 more)

### Community 63 - "mensualidad_repository_impl.dart"
Cohesion: 0.12
Nodes (16): ../../../core/network/api_client.dart, ../domain/mensualidad_repository.dart, dtos/mensualidad_dto.dart, dtos/mensualidad_page_dto.dart, cancelar, crear, _dio, listar (+8 more)

### Community 64 - "celdas_screen.dart"
Cohesion: 0.12
Nodes (16): build, CeldasScreen, _CeldasScreenState, count, createState, dispose, _entradaController, _entradaDisparada (+8 more)

### Community 65 - "turno_cierre_screen_test.dart"
Cohesion: 0.12
Nodes (15): package:intl/date_symbol_data_local.dart, package:parqueadero_app/core/utils/money.dart, package:parqueadero_app/features/turnos/presentation/turno_cierre_screen.dart, main, nbsp, arqueoEnVivo, arqueoFinal, arqueoPendiente (+7 more)

### Community 66 - "turno_cierre_notifier.dart"
Cohesion: 0.19
Nodes (14): abrir_turno_state.dart, turnoRepositoryProvider, abrir, AbrirTurnoNotifier, build, turnoActivoNotifierProvider, build, cerrar (+6 more)

### Community 67 - "@JsonSerializable"
Cohesion: 0.13
Nodes (15): @JsonSerializable, celda_dto.dart, CeldaPageDto, CeldaPageMetaDto, data, fromJson, meta, page (+7 more)

### Community 68 - "celda_list_notifier.dart"
Cohesion: 0.12
Nodes (15): celda_list_state.dart, build, _cargarTicketInfoPorCeldaId, CeldaListNotifier, _isRefreshing, limpiarFiltros, _pollTimer, reemplazarCelda (+7 more)

### Community 69 - "login_screen.dart"
Cohesion: 0.14
Nodes (15): ../../../core/widgets/error_banner.dart, loginControllerProvider, build, createState, dispose, _emailController, _emailRegex, _focusedBorder (+7 more)

### Community 70 - "refresh_interceptor_test.dart"
Cohesion: 0.12
Nodes (15): dart:convert, DioException, HttpClientAdapter, MockTokenStorage, package:parqueadero_app/core/network/refresh_interceptor.dart, package:parqueadero_app/core/network/session_events.dart, package:parqueadero_app/features/auth/data/token_storage.dart, adapter (+7 more)

### Community 71 - "../domain/ticket.dart"
Cohesion: 0.14
Nodes (13): ../domain/ticket.dart, Ticket, buscado, errorMessage, isLoading, ticket, error, SalidaStep (+5 more)

### Community 72 - "List"
Cohesion: 0.12
Nodes (14): copyWith, errorMessage, horarios, isLoading, data, fromJson, MensualidadPageDto, MensualidadPageMetaDto (+6 more)

### Community 73 - "turno_dto.dart"
Cohesion: 0.12
Nodes (15): apertura, baseInicial, cierre, createdAt, diferencia, efectivoContado, efectivoEsperado, estado (+7 more)

### Community 74 - "abrir_turno_screen.dart"
Cohesion: 0.16
Nodes (13): abrir_turno_notifier.dart, FormState, tapFeedback, abrirTurnoNotifierProvider, AbrirTurnoScreen, _AbrirTurnoScreenState, _baseInicialController, build (+5 more)

### Community 75 - "../../../core/network/api_exception.dart"
Cohesion: 0.15
Nodes (12): buscar_placa_state.dart, ../../../core/network/api_exception.dart, ../data/ticket_repository_impl.dart, build, build, buscar, celdaId, build (+4 more)

### Community 76 - "ticket_repository.dart"
Cohesion: 0.13
Nodes (14): cobro_preview.dart, data, hayMas, listar, obtenerPorId, page, perPage, previsualizarCobro (+6 more)

### Community 77 - "nuevo_usuario_screen.dart"
Cohesion: 0.15
Nodes (14): ../../../core/utils/validators.dart, nuevoUsuarioNotifierProvider, build, createState, dispose, _emailController, _formKey, _nombreController (+6 more)

### Community 78 - "DateTime"
Cohesion: 0.13
Nodes (13): DateTime, desglose_item.dart, int?, TarifaSimulacionNotifier, errorMessage, isLoading, TarifaSimulacionState, tieneResultado (+5 more)

### Community 79 - "usuario_list_notifier.dart"
Cohesion: 0.13
Nodes (14): agregarUsuario, build, cargar, cargarMas, _isLoading, limpiarFiltros, _perPage, reemplazarUsuario (+6 more)

### Community 80 - "usuario.dart"
Cohesion: 0.14
Nodes (13): admin,, activo, baseInicialTurno, createdAt, email, fromBackend, hashCode, id (+5 more)

### Community 81 - "turno_repository.dart"
Cohesion: 0.14
Nodes (13): arqueo_turno.dart, abrir, cerrar, completarArqueo, data, hayMas, listar, obtenerArqueo (+5 more)

### Community 82 - "usuario_list_state.dart"
Cohesion: 0.14
Nodes (13): bool?, RolUsuario, activoFiltro, copyWith, errorMessage, hayMas, isLoading, isLoadingMore (+5 more)

### Community 83 - "celda_accion_notifier.dart"
Cohesion: 0.15
Nodes (13): celda_accion_state.dart, celda_list_notifier.dart, ../data/celda_repository_impl.dart, ../domain/celda_repository.dart, celdaRepositoryProvider, build, CeldaAccionNotifier, celdaId (+5 more)

### Community 84 - "mensualidad_filtros_bar.dart"
Cohesion: 0.16
Nodes (12): ../domain/mensualidad.dart, estado_pago_style.dart, EstadoPagoMensualidad, build, estado, EstadoPagoChip, createState, dispose (+4 more)

### Community 85 - "celda.dart"
Cohesion: 0.14
Nodes (13): Celda, codigo, createdAt, estado, fromBackend, hashCode, id, mantenimiento (+5 more)

### Community 86 - "mensualidad_dto.dart"
Cohesion: 0.14
Nodes (13): celdaId, createdAt, estadoPago, fechaFin, fechaInicio, fechaPago, fromJson, id (+5 more)

### Community 87 - "mensualidad_list_state.dart"
Cohesion: 0.14
Nodes (13): copyWith, errorMessage, estadoPagoFiltro, hayMas, isLoading, isLoadingMore, mensualidades, MensualidadListState (+5 more)

### Community 88 - "tarifa_dto.dart"
Cohesion: 0.14
Nodes (13): createdAt, fromJson, id, TarifaDto, tipoVehiculo, toDomain, updatedAt, valorMes (+5 more)

### Community 89 - "pago_dto.dart"
Cohesion: 0.14
Nodes (13): createdAt, estado, fecha, fromJson, id, mensualidadId, metodo, monto (+5 more)

### Community 90 - "ticket_list_notifier.dart"
Cohesion: 0.14
Nodes (13): build, cargar, cargarMas, _isLoading, limpiarFiltros, _perPage, refrescar, setEstadoFiltro (+5 more)

### Community 91 - "turno_list_notifier.dart"
Cohesion: 0.14
Nodes (13): build, cargar, cargarMas, _isLoading, limpiarFiltros, _perPage, refrescar, setEstadoFiltro (+5 more)

### Community 92 - "turno_list_state.dart"
Cohesion: 0.14
Nodes (13): copyWith, desdeFiltro, errorMessage, estadoFiltro, hastaFiltro, hayMas, isLoading, isLoadingMore (+5 more)

### Community 93 - "operador_home_dashboard_test.dart"
Cohesion: 0.14
Nodes (13): Material, package:parqueadero_app/features/auth/presentation/widgets/operador_home_dashboard.dart, authRepository, celda, celdaRepository, main, operador, pumpDashboard (+5 more)

### Community 94 - "celda_card_test.dart"
Cohesion: 0.14
Nodes (13): package:parqueadero_app/features/celdas/presentation/widgets/celda_accion_rapida_sheet.dart, package:parqueadero_app/features/celdas/presentation/widgets/celda_card.dart, Route /celdas/c1, authRepository, celda, celdaRepository, main, MockAuthRepository (+5 more)

### Community 95 - "celda_accion_rapida_sheet_test.dart"
Cohesion: 0.15
Nodes (12): ConstrainedBox, package:parqueadero_app/core/theme/app_breakpoints.dart, authRepository, main, MockAuthRepository, operador, pumpSheet, rutaVisitada (+4 more)

### Community 96 - "mensualidadListNotifierProvider"
Cohesion: 0.17
Nodes (12): mensualidadRepositoryProvider, cancelar, MensualidadAccionNotifier, errorMessage, isLoading, MensualidadAccionState, mensualidadListNotifierProvider, build (+4 more)

### Community 97 - "mensualidad_list_notifier.dart"
Cohesion: 0.15
Nodes (12): build, cargar, cargarMas, _isLoading, limpiarFiltros, _perPage, reemplazarMensualidad, refrescar (+4 more)

### Community 98 - "turno_filtros_bar.dart"
Cohesion: 0.21
Nodes (12): turnoListNotifierProvider, build, TurnosHistorialScreen, build, createState, dispose, _elegirRango, initState (+4 more)

### Community 99 - "turno_activo_indicator.dart"
Cohesion: 0.17
Nodes (12): actionLabel, _Banner, createState, _dialogoMostrado, onAction, onVerArqueo, _preguntandoInicio, style (+4 more)

### Community 100 - "celda_detail_screen_test.dart"
Cohesion: 0.15
Nodes (12): package:parqueadero_app/features/celdas/presentation/celda_detail_screen.dart, authRepository, celda, celdaRepository, main, MockAuthRepository, MockCeldaRepository, MockTicketRepository (+4 more)

### Community 101 - "nueva_mensualidad_screen_test.dart"
Cohesion: 0.15
Nodes (12): package:parqueadero_app/features/mensualidades/presentation/nueva_mensualidad_screen.dart, authRepository, celda, celdaRepository, main, mensualidadRepository, MockAuthRepository, MockCeldaRepository (+4 more)

### Community 102 - "celda_detail_screen.dart"
Cohesion: 0.18
Nodes (10): celda_accion_notifier.dart, celda_estado_badge.dart, ../../../core/utils/tipo_vehiculo_label.dart, ../../../core/widgets/button_spinner.dart, celdaId, celdaId, showCeldaQuickActions, ../../tickets/presentation/ticket_abierto_de_celda_notifier.dart (+2 more)

### Community 103 - "../domain/celda.dart"
Cohesion: 0.20
Nodes (10): celda_estado_style.dart, ../domain/celda.dart, EstadoCelda, build, CeldaEstadoBadge, estado, size, build (+2 more)

### Community 104 - "session_notifier.dart"
Cohesion: 0.21
Nodes (11): ../../../core/network/session_events.dart, ../data/auth_repository_impl.dart, sessionEventsProvider, authRepositoryProvider, build, login, logout, _restore (+3 more)

### Community 105 - "turno_cierre_state.dart"
Cohesion: 0.18
Nodes (10): ../domain/arqueo_turno.dart, ArqueoTurno, error, resultado, step, TurnoCierreState, TurnoCierreStep, arqueo (+2 more)

### Community 106 - "turno_repository_impl.dart"
Cohesion: 0.17
Nodes (11): ../domain/turno_repository.dart, dtos/arqueo_turno_dto.dart, dtos/turno_dto.dart, dtos/turno_page_dto.dart, abrir, cerrar, completarArqueo, _dio (+3 more)

### Community 107 - "vehiculo_dto.dart"
Cohesion: 0.17
Nodes (11): ../../domain/vehiculo.dart, createdAt, fromJson, id, placa, propietarioNombre, propietarioTelefono, tipo (+3 more)

### Community 108 - "horario.dart"
Cohesion: 0.17
Nodes (11): int get, apertura, cierre, createdAt, esVigente, hashCode, id, operator (+3 more)

### Community 109 - "home_screen_test.dart"
Cohesion: 0.17
Nodes (11): package:parqueadero_app/features/auth/presentation/home_screen.dart, authRepository, celdaRepository, main, MockAuthRepository, MockCeldaRepository, MockTicketRepository, pumpHome (+3 more)

### Community 110 - "api_client.dart"
Cohesion: 0.18
Nodes (10): auth_interceptor.dart, ../config/app_config.dart, ../../features/auth/data/token_storage.dart, config, dio, dioProvider, sessionEvents, tokenStorage (+2 more)

### Community 111 - "usuario_repository.dart"
Cohesion: 0.18
Nodes (10): bool get, actualizar, crear, data, hayMas, listar, page, perPage (+2 more)

### Community 112 - "dart:async"
Cohesion: 0.20
Nodes (10): dart:async, _controller, dispose, emit, events, SessionEvents, SessionEventType, stream (+2 more)

### Community 113 - "token_storage.dart"
Cohesion: 0.18
Nodes (10): FlutterSecureStorage, _accessTokenKey, clear, readAccessToken, readRefreshToken, _refreshTokenKey, saveTokens, _storage (+2 more)

### Community 114 - "tiempo_transcurrido_text.dart"
Cohesion: 0.20
Nodes (10): build, createState, dispose, horaEntrada, initState, style, TiempoTranscurridoText, _TiempoTranscurridoTextState (+2 more)

### Community 115 - "celda_dto.dart"
Cohesion: 0.18
Nodes (10): CeldaDto, codigo, createdAt, estado, fromJson, id, tipoPermitido, toDomain (+2 more)

### Community 116 - "horario_dto.dart"
Cohesion: 0.18
Nodes (10): apertura, cierre, createdAt, fromJson, HorarioDto, id, toDomain, updatedAt (+2 more)

### Community 117 - "mensualidad_repository.dart"
Cohesion: 0.18
Nodes (10): cancelar, crear, data, hayMas, listar, MensualidadPageResult, page, perPage (+2 more)

### Community 118 - "tarifa_grupo_card.dart"
Cohesion: 0.22
Nodes (10): Tarifa, tarifaAccionNotifierProvider, build, _confirmarCerrar, _HistoricoRow, tarifa, TarifaGrupoCard, tarifas (+2 more)

### Community 119 - "arqueo_summary_view.dart"
Cohesion: 0.18
Nodes (10): arqueo, ArqueoSummaryView, build, destacado, diferenciaTexto, _Fila, label, valor (+2 more)

### Community 120 - "cobro_preview_notifier_test.dart"
Cohesion: 0.18
Nodes (10): package:fake_async/fake_async.dart, package:parqueadero_app/features/tickets/domain/cobro_preview.dart, package:parqueadero_app/features/tickets/presentation/cobro_preview_notifier.dart, container, main, mantenerVivo, previewBloques, previewManual (+2 more)

### Community 121 - "recibo_screen_test.dart"
Cohesion: 0.18
Nodes (10): package:parqueadero_app/features/tickets/domain/recibo.dart, package:parqueadero_app/features/tickets/presentation/recibo_screen.dart, establecimiento, main, MockTicketRepository, pumpReciboScreen, recibo, ticketAbierto (+2 more)

### Community 122 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 123 - "usuario_page_dto.dart"
Cohesion: 0.20
Nodes (9): ../../auth/data/dtos/usuario_dto.dart, data, fromJson, meta, page, perPage, total, UsuarioPageDto (+1 more)

### Community 124 - "registrar_entrada_notifier.dart"
Cohesion: 0.20
Nodes (8): ../../celdas/presentation/celda_list_notifier.dart, build, registrar, RegistrarEntradaNotifier, errorMessage, isLoading, RegistrarEntradaState, registrar_entrada_state.dart

### Community 125 - "refresh_interceptor.dart"
Cohesion: 0.20
Nodes (9): Completer, ../../features/auth/data/dtos/refresh_response_dto.dart, _dio, _doRefresh, onError, _refreshAccessToken, _refreshCompleter, _sessionEvents (+1 more)

### Community 126 - "nueva_mensualidad_notifier.dart"
Cohesion: 0.22
Nodes (8): ../data/mensualidad_repository_impl.dart, build, mensualidadId, build, crear, mensualidad_accion_state.dart, mensualidad_list_notifier.dart, nueva_mensualidad_state.dart

### Community 127 - "recibo_view.dart"
Cohesion: 0.20
Nodes (9): desglose_view.dart, ../../domain/recibo.dart, Recibo, build, kReciboAnchoMm80, _pieStyle, recibo, ReciboView (+1 more)

### Community 128 - "salida_notifier.dart"
Cohesion: 0.20
Nodes (8): ../domain/pago.dart, build, confirmarSalida, SalidaNotifier, ticketId, SalidaState, metodoPagoLabel, salida_state.dart

### Community 129 - "horario_page_dto.dart"
Cohesion: 0.20
Nodes (9): horario_dto.dart, data, fromJson, HorarioPageDto, HorarioPageMetaDto, meta, page, perPage (+1 more)

### Community 130 - "String?"
Cohesion: 0.20
Nodes (7): errorMessage, isLoading, errorMessage, isLoading, errorMessage, isLoading, String?

### Community 131 - "tarifa_page_dto.dart"
Cohesion: 0.20
Nodes (9): data, fromJson, meta, page, perPage, TarifaPageDto, TarifaPageMetaDto, total (+1 more)

### Community 132 - "ticket_page_dto.dart"
Cohesion: 0.20
Nodes (9): data, fromJson, meta, page, perPage, TicketPageDto, TicketPageMetaDto, total (+1 more)

### Community 133 - "turno_page_dto.dart"
Cohesion: 0.20
Nodes (9): data, fromJson, meta, page, perPage, total, TurnoPageDto, TurnoPageMetaDto (+1 more)

### Community 134 - "nueva_tarifa_notifier.dart"
Cohesion: 0.25
Nodes (7): ../domain/tarifa.dart, build, crear, build, TarifaFiltrosBar, nueva_tarifa_state.dart, tarifa_list_notifier.dart

### Community 135 - "validators.dart"
Cohesion: 0.22
Nodes (8): _emailRegex, emailValidator, hasMatch, placaValidator, requiredError, requiredIntegerValidator, requiredValidator, tryParse

### Community 136 - "tarifaListNotifierProvider"
Cohesion: 0.25
Nodes (9): tarifaRepositoryProvider, cerrar, TarifaAccionNotifier, refrescar, tarifaListNotifierProvider, build, TarifasScreen, Route /tarifas/nueva (+1 more)

### Community 137 - "turno_detail_notifier.dart"
Cohesion: 0.25
Nodes (7): ../data/turno_repository_impl.dart, build, cargar, TurnoDetailNotifier, turnoId, TurnoDetailState, turno_detail_state.dart

### Community 138 - "_"
Cohesion: 0.29
Nodes (8): _, AppColors, asfalto, concreto, demarcacion, linea, tinta, verdeSenal

### Community 139 - "_"
Cohesion: 0.29
Nodes (8): _, AppSpacing, gutter, lg, md, sm, xl, xs

### Community 140 - "_"
Cohesion: 0.29
Nodes (8): Usuario, _, authenticated, checking, SessionStatus, status, unauthenticated, usuario

### Community 141 - "login_controller.dart"
Cohesion: 0.29
Nodes (7): build, error, isLoading, LoginController, LoginState, submit, session_notifier.dart

### Community 142 - "_"
Cohesion: 0.33
Nodes (7): _, AppMotion, curve, effective, fast, medium, slow

### Community 143 - "animated_count_text.dart"
Cohesion: 0.29
Nodes (6): AnimatedCountText, build, style, value, TextStyle?, ../theme/app_motion.dart

### Community 144 - "tarifa_list_notifier.dart"
Cohesion: 0.29
Nodes (6): build, _isLoading, setTipoFiltro, TarifaListNotifier, TarifaListState, tarifa_list_state.dart

### Community 145 - "tarifa_list_state.dart"
Cohesion: 0.29
Nodes (6): copyWith, errorMessage, isLoading, tarifas, tipoFiltro, _unset

### Community 146 - "cobro_preview_state.dart"
Cohesion: 0.29
Nodes (6): CobroPreview, copyWith, error, esTerminal, isLoading, preview

### Community 147 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.29
Nodes (5): package:flutter_test/flutter_test.dart, package:parqueadero_app/core/theme/app_theme.dart, package:parqueadero_app/core/utils/elapsed_time.dart, main, main

### Community 148 - "package:mocktail/mocktail.dart"
Cohesion: 0.29
Nodes (6): package:mocktail/mocktail.dart, package:parqueadero_app/features/tickets/presentation/ticket_abierto_de_celda_notifier.dart, container, main, ticket, ticketRepository

### Community 149 - "../domain/turno.dart"
Cohesion: 0.33
Nodes (5): ../domain/turno.dart, Turno, errorMessage, isLoading, turno

### Community 150 - "_"
Cohesion: 0.40
Nodes (6): _, AppBreakpoints, contentMaxWidth, gridMaxWidth, mobile, tablet

### Community 151 - "static const"
Cohesion: 0.40
Nodes (6): _, AppElevation, flat, low, raised, static const

### Community 152 - "package:json_annotation/json_annotation.dart"
Cohesion: 0.33
Nodes (5): accessToken, fromJson, RefreshResponseDto, refreshToken, package:json_annotation/json_annotation.dart

### Community 153 - "vigencia_chip.dart"
Cohesion: 0.33
Nodes (5): VigenciaMensualidad, build, vigencia, VigenciaChip, vigencia_style.dart

### Community 154 - "turno_estado_chip.dart"
Cohesion: 0.33
Nodes (5): EstadoTurno, build, estado, TurnoEstadoChip, turno_estado_style.dart

### Community 155 - "tarifa_accion_notifier.dart"
Cohesion: 0.40
Nodes (4): ../data/tarifa_repository_impl.dart, build, tarifaId, tarifa_accion_state.dart

### Community 156 - "_"
Cohesion: 0.50
Nodes (5): _, apiBaseUrl, AppConfig, appConfigProvider, fromEnvironment

### Community 157 - "_"
Cohesion: 0.50
Nodes (5): _, AppRadius, lg, md, sm

### Community 158 - "NuevaMensualidadNotifier"
Cohesion: 0.40
Nodes (4): NuevaMensualidadNotifier, errorMessage, isLoading, NuevaMensualidadState

### Community 159 - "NuevaTarifaNotifier"
Cohesion: 0.40
Nodes (4): NuevaTarifaNotifier, errorMessage, isLoading, NuevaTarifaState

### Community 160 - "ticket_abierto_de_celda_state.dart"
Cohesion: 0.40
Nodes (4): TicketAbiertoDeCeldaNotifier, errorMessage, isLoading, TicketAbiertoDeCeldaState

### Community 161 - "../../domain/desglose_item.dart"
Cohesion: 0.50
Nodes (3): ../../domain/desglose_item.dart, desgloseFromJson, map

### Community 162 - "elapsed_time.dart"
Cohesion: 0.50
Nodes (3): formatElapsed, horas, minutos

### Community 163 - "upper_case_text_formatter.dart"
Cohesion: 0.50
Nodes (3): formatEditUpdate, UpperCaseTextFormatter, TextInputFormatter

### Community 164 - "tarifa_accion_state.dart"
Cohesion: 0.50
Nodes (3): errorMessage, isLoading, TarifaAccionState

### Community 165 - "abrir_turno_state.dart"
Cohesion: 0.50
Nodes (3): AbrirTurnoState, errorMessage, isLoading

### Community 166 - "build"
Cohesion: 0.50
Nodes (4): build, Route /turnos/abrir, main, pumpAbrirTurnoScreen

### Community 169 - "RefreshInterceptor"
Cohesion: 0.67
Nodes (3): Interceptor, AuthInterceptor, RefreshInterceptor

## Knowledge Gaps
- **1596 isolated node(s):** `arqueo`, `authRepository`, `container`, `main`, `operador` (+1591 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1889 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `_` to `package:flutter/material.dart`, `../domain/ticket.dart`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Why does `_` connect `_` to `static const`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Why does `_` connect `_` to `package:flutter/material.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **What connects `arqueo`, `authRepository`, `container` to the rest of the system?**
  _1596 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `turno_cierre_notifier_test.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.047519217330538085 - nodes in this community are weakly interconnected._
- **Should `usuario_detail_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.054078014184397165 - nodes in this community are weakly interconnected._
- **Should `mensualidades_screen_test.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05735430157261795 - nodes in this community are weakly interconnected._