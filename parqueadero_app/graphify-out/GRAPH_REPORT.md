# Graph Report - parqueadero_app  (2026-09-12)

## Corpus Check
- 309 files · ~88,774 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2941 nodes · 5197 edges · 163 communities (158 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `86207587`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- MockAuthRepository
- usuario_detail_screen.dart
- package:flutter_test/flutter_test.dart
- package:parqueadero_app/core/network/api_exception.dart
- app_router.dart
- package:parqueadero_app/features/auth/domain/usuario.dart
- mensualidad_detail_screen.dart
- horarios_screen_test.dart
- package:flutter_riverpod/flutter_riverpod.dart
- ticket_detail_screen.dart
- _
- registrar_salida_screen.dart
- api_exception.dart
- Mock
- sessionNotifierProvider
- nueva_mensualidad_screen_test.dart
- ../../../core/theme/app_spacing.dart
- recibo_dto.dart
- package:go_router/go_router.dart
- ticket.dart
- ticket_dto.dart
- celda_list_state.dart
- ../../../../core/utils/bogota_time.dart
- ../../../core/network/api_exception.dart
- StatelessWidget
- dashboard_metric_card.dart
- cobro_preview_notifier.dart
- celdas_screen_test.dart
- nueva_tarifa_screen.dart
- recibo.dart
- tarifa_repository_impl.dart
- nuevo_horario_screen.dart
- turno_filtros_bar.dart
- usuario_repository_test.dart
- ticket_repository_impl.dart
- ../theme/app_spacing.dart
- empty_state.dart
- login_screen_test.dart
- nueva_mensualidad_screen.dart
- registrar_entrada_screen.dart
- pago.dart
- _
- celda_accion_rapida_sheet.dart
- _
- loading_skeleton.dart
- tarifa.dart
- tarifa_repository_test.dart
- mensualidad.dart
- ticket_list_state.dart
- arqueo_turno_dto.dart
- dashboard_action_group.dart
- registrar_salida_screen_test.dart
- int?
- build
- buscar_placa_screen.dart
- celda_repository_impl.dart
- auth_repository_impl.dart
- package:flutter/material.dart
- registrar_entrada_screen_test.dart
- desglose_item.dart
- arqueo_turno.dart
- turno.dart
- ../../../core/domain/tipo_vehiculo.dart
- horario_repository_impl.dart
- celdas_screen.dart
- turno_cierre_screen_test.dart
- turno_cierre_notifier.dart
- package:json_annotation/json_annotation.dart
- celda_list_notifier.dart
- login_screen.dart
- auth_repository_test.dart
- ../domain/ticket.dart
- mensualidad_page_dto.dart
- turno_dto.dart
- abrir_turno_screen.dart
- ticket_detail_notifier.dart
- ticket_repository.dart
- nuevo_usuario_screen.dart
- DateTime?
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
- Sistema de diseño — App de Parqueadero
- mensualidad_repository_test.dart
- mensualidad_accion_notifier.dart
- mensualidad_list_notifier.dart
- ticket_repository_test.dart
- turno_activo_indicator.dart
- celda_detail_screen_test.dart
- _LoadingSkeletonState
- celda_detail_screen.dart
- ../domain/celda.dart
- session_notifier.dart
- _CeldaAccionRapidaSheetState
- turno_repository_impl.dart
- String?
- horario.dart
- turno_activo_notifier.dart
- package:dio/dio.dart
- usuario_repository.dart
- session_events.dart
- token_storage.dart
- tiempo_transcurrido_text.dart
- celda_dto.dart
- horario_dto.dart
- mensualidad_repository.dart
- tarifa_grupo_card.dart
- arqueo_summary_view.dart
- ../../domain/mensualidad.dart
- tarifa_simulacion_notifier.dart
- manifest.json
- usuario_page_dto.dart
- app_page_transitions.dart
- TipoVehiculo
- Dio
- recibo_view.dart
- Notifier
- horario_page_dto.dart
- material_hero.dart
- List
- ticket_page_dto.dart
- @JsonSerializable
- nueva_tarifa_notifier.dart
- validators.dart
- ../../../../core/utils/tipo_vehiculo_label.dart
- AGENTS.md — parqueadero_app
- _
- _
- _
- celda_repository.dart
- _
- animated_count_text.dart
- tarifa_list_notifier.dart
- tarifa_list_state.dart
- cobro_preview_state.dart
- parqueadero_app
- ../../domain/turno.dart
- _
- static const
- vigencia_chip.dart
- _
- _
- NuevaMensualidadNotifier
- NuevaTarifaNotifier
- ticket_abierto_de_celda_notifier.dart
- elapsed_time.dart
- TarifaAccionNotifier
- print_launcher_web.dart
- rol_usuario_label.dart
- print_launcher.dart
- print_launcher_stub.dart

## God Nodes (most connected - your core abstractions)
1. `sessionNotifierProvider` - 46 edges
2. `AuthRepository` - 33 edges
3. `TicketRepository` - 25 edges
4. `celdaListNotifierProvider` - 24 edges
5. `_` - 23 edges
6. `TurnoRepository` - 18 edges
7. `CeldaRepository` - 16 edges
8. `ApiException` - 12 edges
9. `_` - 12 edges
10. `_` - 12 edges

## Surprising Connections (you probably didn't know these)
- `MockAuthRepository` --implements--> `AuthRepository`  [EXTRACTED]
  test/unit/abrir_turno_notifier_test.dart → lib/features/auth/domain/auth_repository.dart
- `MockAuthRepository` --implements--> `AuthRepository`  [EXTRACTED]
  test/unit/turno_activo_notifier_test.dart → lib/features/auth/domain/auth_repository.dart
- `MockAuthRepository` --implements--> `AuthRepository`  [EXTRACTED]
  test/unit/turno_cierre_notifier_test.dart → lib/features/auth/domain/auth_repository.dart
- `MockAuthRepository` --implements--> `AuthRepository`  [EXTRACTED]
  test/widget/admin_home_dashboard_test.dart → lib/features/auth/domain/auth_repository.dart
- `MockAuthRepository` --implements--> `AuthRepository`  [EXTRACTED]
  test/widget/buscar_placa_screen_test.dart → lib/features/auth/domain/auth_repository.dart

## Import Cycles
- None detected.

## Communities (163 total, 5 thin omitted)

### Community 0 - "MockAuthRepository"
Cohesion: 0.03
Nodes (98): Icon, MockAuthRepository, MockTurnoRepository, package:parqueadero_app/features/auth/domain/auth_repository.dart, package:parqueadero_app/features/auth/presentation/session_notifier.dart, package:parqueadero_app/features/auth/presentation/session_state.dart, package:parqueadero_app/features/turnos/data/turno_repository_impl.dart, package:parqueadero_app/features/turnos/domain/arqueo_turno.dart (+90 more)

### Community 1 - "usuario_detail_screen.dart"
Cohesion: 0.05
Nodes (45): ../../../auth/domain/usuario.dart, ConsumerStatefulWidget, ../../../../core/utils/rol_usuario_label.dart, ../data/usuario_repository_impl.dart, NuevoHorarioScreen, build, crear, NuevoUsuarioNotifier (+37 more)

### Community 2 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.05
Nodes (45): MockMensualidadRepository, package:flutter_test/flutter_test.dart, package:mocktail/mocktail.dart, package:parqueadero_app/core/domain/tipo_vehiculo.dart, package:parqueadero_app/core/theme/app_theme.dart, package:parqueadero_app/core/utils/elapsed_time.dart, package:parqueadero_app/features/mensualidades/domain/mensualidad.dart, package:parqueadero_app/features/mensualidades/domain/mensualidad_repository.dart (+37 more)

### Community 3 - "package:parqueadero_app/core/network/api_exception.dart"
Cohesion: 0.06
Nodes (42): MockTarifaRepository, package:parqueadero_app/core/network/api_exception.dart, package:parqueadero_app/core/widgets/acceso_restringido.dart, package:parqueadero_app/features/tarifas/data/tarifa_repository_impl.dart, package:parqueadero_app/features/tarifas/domain/tarifa.dart, package:parqueadero_app/features/tarifas/domain/tarifa_repository.dart, package:parqueadero_app/features/tarifas/presentation/nueva_tarifa_notifier.dart, package:parqueadero_app/features/tarifas/presentation/nueva_tarifa_screen.dart (+34 more)

### Community 4 - "app_router.dart"
Cohesion: 0.05
Nodes (42): ChangeNotifier, core/config/app_config.dart, core/router/app_router.dart, core/theme/app_theme.dart, ../../features/auth/presentation/home_screen.dart, ../../features/auth/presentation/login_screen.dart, ../../features/auth/presentation/session_notifier.dart, ../../features/auth/presentation/session_state.dart (+34 more)

### Community 5 - "package:parqueadero_app/features/auth/domain/usuario.dart"
Cohesion: 0.05
Nodes (50): UsuarioRepository, MockUsuarioRepository, package:parqueadero_app/features/auth/data/auth_repository_impl.dart, package:parqueadero_app/features/auth/domain/usuario.dart, package:parqueadero_app/features/usuarios/data/usuario_repository_impl.dart, package:parqueadero_app/features/usuarios/domain/usuario_repository.dart, package:parqueadero_app/features/usuarios/presentation/nuevo_usuario_notifier.dart, package:parqueadero_app/features/usuarios/presentation/nuevo_usuario_screen.dart (+42 more)

### Community 6 - "mensualidad_detail_screen.dart"
Cohesion: 0.09
Nodes (27): ../../auth/presentation/session_notifier.dart, ../../../core/widgets/acceso_restringido.dart, ../../../core/widgets/empty_state.dart, ../../../core/widgets/error_state.dart, ../../../core/widgets/list_item_skeleton.dart, mensualidadAccionNotifierProvider, build, _confirmarCancelar (+19 more)

### Community 7 - "horarios_screen_test.dart"
Cohesion: 0.05
Nodes (43): horario.dart, HorarioRepositoryImpl, crear, HorarioRepository, listarTodas, MockHorarioRepository, package:parqueadero_app/features/horarios/data/horario_repository_impl.dart, package:parqueadero_app/features/horarios/domain/horario.dart (+35 more)

### Community 8 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.03
Nodes (79): ConstrainedBox, Hero, MockTicketRepository, package:fake_async/fake_async.dart, package:flutter_riverpod/flutter_riverpod.dart, package:parqueadero_app/core/theme/app_breakpoints.dart, package:parqueadero_app/features/celdas/presentation/reloj_notifier.dart, package:parqueadero_app/features/celdas/presentation/widgets/celda_accion_rapida_sheet.dart (+71 more)

### Community 9 - "ticket_detail_screen.dart"
Cohesion: 0.14
Nodes (15): ../../../core/utils/print/print_launcher.dart, ../../../core/widgets/detail_skeleton.dart, build, ReciboScreen, ticketId, ticketDetailNotifierProvider, build, TicketDetailScreen (+7 more)

### Community 10 - "_"
Cohesion: 0.11
Nodes (22): Color, ../../../../core/theme/status_style.dart, build, ButtonSpinner, color, size, _, CeldaEstadoStyle (+14 more)

### Community 11 - "registrar_salida_screen.dart"
Cohesion: 0.13
Nodes (14): cobro_preview_notifier.dart, ../../../core/widgets/tiempo_transcurrido_text.dart, createState, dispose, _metodo, montoRecibido, _montoRecibidoController, preview (+6 more)

### Community 12 - "api_exception.dart"
Cohesion: 0.14
Nodes (13): DioExceptionType, ApiErrorDetail, code, details, field, fromDioException, fromJson, fromResponse (+5 more)

### Community 13 - "Mock"
Cohesion: 0.04
Nodes (75): CeldaRepository, MensualidadRepository, TarifaRepositoryImpl, cerrar, crear, listarTodas, simular, TarifaRepository (+67 more)

### Community 14 - "sessionNotifierProvider"
Cohesion: 0.13
Nodes (27): ConsumerWidget, ../domain/usuario.dart, build, HomeScreen, sessionNotifierProvider, AdminHomeDashboard, _CeldasLibresCard, celdaAccionNotifierProvider (+19 more)

### Community 15 - "nueva_mensualidad_screen_test.dart"
Cohesion: 0.04
Nodes (61): MockCeldaRepository, package:parqueadero_app/features/auth/presentation/widgets/admin_home_dashboard.dart, package:parqueadero_app/features/celdas/data/celda_repository_impl.dart, package:parqueadero_app/features/celdas/domain/celda.dart, package:parqueadero_app/features/celdas/domain/celda_repository.dart, package:parqueadero_app/features/celdas/presentation/celda_accion_notifier.dart, package:parqueadero_app/features/celdas/presentation/celda_list_notifier.dart, package:parqueadero_app/features/mensualidades/presentation/nueva_mensualidad_screen.dart (+53 more)

### Community 16 - "../../../core/theme/app_spacing.dart"
Cohesion: 0.06
Nodes (39): celda_accion_rapida_sheet.dart, celda_quick_actions_sheet.dart, ../../../../core/theme/app_breakpoints.dart, ../../../../core/theme/app_colors.dart, ../../../../core/theme/app_elevation.dart, ../../../../core/theme/app_radius.dart, ../../../core/theme/app_spacing.dart, ../../../../core/utils/haptics.dart (+31 more)

### Community 17 - "recibo_dto.dart"
Cohesion: 0.06
Nodes (32): desglose_item_dto.dart, ../domain/cobro_preview.dart, ../../domain/desglose_item.dart, cobroPreviewFromJson, desgloseFromJson, map, celda, ciudad (+24 more)

### Community 18 - "package:go_router/go_router.dart"
Cohesion: 0.09
Nodes (25): ../../../core/widgets/error_banner.dart, build, ticket, TicketListItem, turnoCierreNotifierProvider, build, _completandoArqueo, _confirmarYCerrar (+17 more)

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
Nodes (29): busquedaFiltro, celdas, celdasFiltradas, celdasFiltradasPorZona, celdasLibresDeTipo, compute, copyWith, _Derivados (+21 more)

### Community 22 - "../../../../core/utils/bogota_time.dart"
Cohesion: 0.09
Nodes (20): ../../../../core/utils/bogota_time.dart, ../../../../core/utils/money.dart, ../../../../core/widgets/material_hero.dart, estado_pago_chip.dart, Mensualidad, build, mensualidad, MensualidadListItem (+12 more)

### Community 23 - "../../../core/network/api_exception.dart"
Cohesion: 0.12
Nodes (17): ../../../core/network/api_exception.dart, ../data/horario_repository_impl.dart, horario_list_notifier.dart, horario_list_state.dart, horarioRepositoryProvider, build, HorarioListNotifier, _isLoading (+9 more)

### Community 24 - "StatelessWidget"
Cohesion: 0.11
Nodes (19): ../../../../core/theme/app_motion.dart, ../../../../core/widgets/animated_count_text.dart, ancho, _BarraOcupacion, borde, build, color, libres (+11 more)

### Community 25 - "dashboard_metric_card.dart"
Cohesion: 0.15
Nodes (12): animated_count_text.dart, build, dark, DashboardMetricCard, errorMessage, icon, isLoading, label (+4 more)

### Community 26 - "cobro_preview_notifier.dart"
Cohesion: 0.17
Nodes (11): cobro_preview_state.dart, dart:async, build, RelojNotifier, _timer, build, _codigosTerminales, _isRefreshing (+3 more)

### Community 27 - "celdas_screen_test.dart"
Cohesion: 0.07
Nodes (28): package:parqueadero_app/core/widgets/animated_count_text.dart, package:parqueadero_app/core/widgets/empty_state.dart, package:parqueadero_app/core/widgets/error_state.dart, package:parqueadero_app/features/celdas/presentation/celdas_screen.dart, package:parqueadero_app/features/celdas/presentation/widgets/celda_grid_skeleton.dart, package:parqueadero_app/features/tickets/domain/recibo.dart, package:parqueadero_app/features/tickets/presentation/recibo_screen.dart, package:parqueadero_app/features/tickets/presentation/tickets_historial_screen.dart (+20 more)

### Community 28 - "nueva_tarifa_screen.dart"
Cohesion: 0.09
Nodes (25): nuevaTarifaNotifierProvider, build, createState, _debounce, dispose, _duracionesPreset, duracionLabel, _duracionMinutos (+17 more)

### Community 29 - "recibo.dart"
Cohesion: 0.08
Nodes (24): celda, ciudad, consecutivo, desglose, direccion, Establecimiento, fechaEmision, horaEntrada (+16 more)

### Community 30 - "tarifa_repository_impl.dart"
Cohesion: 0.20
Nodes (9): ../domain/tarifa_repository.dart, dtos/tarifa_dto.dart, dtos/tarifa_page_dto.dart, cerrar, crear, _dio, listarTodas, _perPage (+1 more)

### Community 31 - "nuevo_horario_screen.dart"
Cohesion: 0.09
Nodes (23): ConsumerState, nuevoHorarioNotifierProvider, _apertura, build, _cierre, createState, _elegirApertura, _elegirCierre (+15 more)

### Community 32 - "turno_filtros_bar.dart"
Cohesion: 0.08
Nodes (27): formatBogota, toBogota, formatMoney, ticketListNotifierProvider, build, TicketsHistorialScreen, build, createState (+19 more)

### Community 33 - "usuario_repository_test.dart"
Cohesion: 0.11
Nodes (16): ../domain/usuario_repository.dart, dtos/usuario_page_dto.dart, actualizar, crear, _dio, listar, UsuarioRepositoryImpl, usuarioRepositoryProvider (+8 more)

### Community 34 - "ticket_repository_impl.dart"
Cohesion: 0.17
Nodes (11): ../domain/ticket_repository.dart, dtos/cobro_preview_dto.dart, dtos/ticket_dto.dart, dtos/ticket_page_dto.dart, _dio, listar, obtenerPorId, previsualizarCobro (+3 more)

### Community 35 - "../theme/app_spacing.dart"
Cohesion: 0.15
Nodes (11): build, DetailSkeleton, lineas, build, error, ErrorBanner, build, ListItemSkeleton (+3 more)

### Community 36 - "empty_state.dart"
Cohesion: 0.15
Nodes (11): actionLabel, build, EmptyState, icon, message, onAction, build, ErrorState (+3 more)

### Community 37 - "login_screen_test.dart"
Cohesion: 0.05
Nodes (36): BoxDecoration, Container, dart:math, ElevatedButton, package:parqueadero_app/core/theme/app_colors.dart, package:parqueadero_app/core/theme/status_style.dart, package:parqueadero_app/features/auth/presentation/login_screen.dart, package:parqueadero_app/features/celdas/presentation/widgets/zona_header.dart (+28 more)

### Community 38 - "nueva_mensualidad_screen.dart"
Cohesion: 0.11
Nodes (19): ../../celdas/domain/celda.dart, DateTimeRange?, nuevaMensualidadNotifierProvider, build, _celda, createState, dispose, _elegirRango (+11 more)

### Community 39 - "registrar_entrada_screen.dart"
Cohesion: 0.06
Nodes (31): ../../celdas/presentation/celda_list_notifier.dart, ../../celdas/presentation/widgets/celda_estado_badge.dart, build, registrar, RegistrarEntradaNotifier, registrarEntradaNotifierProvider, build, celdaId (+23 more)

### Community 40 - "pago.dart"
Cohesion: 0.09
Nodes (21): efectivo,
  tarjeta,, anulado, createdAt, estado, EstadoPago, fecha, fromBackend, hashCode (+13 more)

### Community 41 - "_"
Cohesion: 0.18
Nodes (13): IconData, _, color, icon, of, StatusStyle, StatusTone, _ (+5 more)

### Community 42 - "celda_accion_rapida_sheet.dart"
Cohesion: 0.07
Nodes (26): class, _buscando, _buscar, celdaId, child, createState, dispose, esAncho (+18 more)

### Community 43 - "_"
Cohesion: 0.10
Nodes (21): app_colors.dart, app_elevation.dart, app_page_transitions.dart, app_radius.dart, app_spacing.dart, _, AppTheme, _colorScheme (+13 more)

### Community 44 - "loading_skeleton.dart"
Cohesion: 0.15
Nodes (12): Animation, AnimationController, double?, borderRadius, build, _controller, createState, dispose (+4 more)

### Community 45 - "tarifa.dart"
Cohesion: 0.14
Nodes (13): createdAt, esVigente, hashCode, id, operator, tipoVehiculo, updatedAt, valorMes (+5 more)

### Community 46 - "tarifa_repository_test.dart"
Cohesion: 0.10
Nodes (20): Exception, ApiException, AppException, NetworkException, MockDio, dio, _dioError, _horarioJson (+12 more)

### Community 47 - "mensualidad.dart"
Cohesion: 0.10
Nodes (19): cancelada, celdaId, createdAt, diasPorVencerDefault, estadoPago, fechaFin, fechaInicio, fechaPago (+11 more)

### Community 48 - "ticket_list_state.dart"
Cohesion: 0.10
Nodes (18): EstadoTicket, copyWith, desdeFiltro, errorMessage, estadoFiltro, hastaFiltro, hayMas, isLoading (+10 more)

### Community 49 - "arqueo_turno_dto.dart"
Cohesion: 0.09
Nodes (21): apertura, ArqueoTurnoDto, baseInicial, cierre, diferencia, efectivo, efectivoContado, efectivoEsperado (+13 more)

### Community 50 - "dashboard_action_group.dart"
Cohesion: 0.17
Nodes (11): build, DashboardActionGroup, DashboardActionItem, _DashboardActionRow, icon, item, items, label (+3 more)

### Community 51 - "registrar_salida_screen_test.dart"
Cohesion: 0.07
Nodes (27): package:parqueadero_app/features/tickets/data/dtos/desglose_item_dto.dart, package:parqueadero_app/features/tickets/data/dtos/recibo_dto.dart, package:parqueadero_app/features/tickets/domain/desglose_item.dart, package:parqueadero_app/features/tickets/domain/pago.dart, package:parqueadero_app/features/tickets/presentation/registrar_salida_screen.dart, Route /salida, main, _establecimientoJson (+19 more)

### Community 52 - "int?"
Cohesion: 0.12
Nodes (15): int?, activo, baseInicialTurno, createdAt, email, fromJson, id, nombre (+7 more)

### Community 53 - "build"
Cohesion: 0.21
Nodes (12): build, build, build, Route /celdas, Route /horarios, Route /mensualidades, Route /tarifas, Route /tickets (+4 more)

### Community 54 - "buscar_placa_screen.dart"
Cohesion: 0.13
Nodes (17): buscar_placa_notifier.dart, ../../../core/utils/elapsed_time.dart, ../../../core/utils/upper_case_text_formatter.dart, buscarPlacaNotifierProvider, build, _buscar, BuscarPlacaScreen, _BuscarPlacaScreenState (+9 more)

### Community 55 - "celda_repository_impl.dart"
Cohesion: 0.22
Nodes (8): dtos/celda_dto.dart, dtos/celda_page_dto.dart, CeldaRepositoryImpl, _dio, listarTodas, marcarMantenimiento, _perPage, volverALibre

### Community 56 - "auth_repository_impl.dart"
Cohesion: 0.18
Nodes (10): ../domain/auth_repository.dart, dtos/login_response_dto.dart, dtos/usuario_dto.dart, AuthRepositoryImpl, _dio, login, logout, restoreSession (+2 more)

### Community 57 - "package:flutter/material.dart"
Cohesion: 0.12
Nodes (12): ../domain/tipo_vehiculo.dart, empty_state.dart, tipoVehiculoIcon, tipoVehiculoLabel, AccesoRestringido, build, build, SplashScreen (+4 more)

### Community 58 - "registrar_entrada_screen_test.dart"
Cohesion: 0.12
Nodes (16): package:parqueadero_app/features/tickets/presentation/registrar_entrada_screen.dart, Route /entrada, authRepository, celdaLibre, celdaRepository, main, operador, pumpEntradaScreen (+8 more)

### Community 59 - "desglose_item.dart"
Cohesion: 0.13
Nodes (17): bloqueNumero, DesgloseBloque, DesgloseItem, DesgloseManual, DesgloseMensualidad, dia, fin, fromBackend (+9 more)

### Community 60 - "arqueo_turno.dart"
Cohesion: 0.07
Nodes (26): ../../domain/arqueo_turno.dart, apertura, ArqueoTurno, baseInicial, cierre, diferencia, efectivo, efectivoContado (+18 more)

### Community 61 - "turno.dart"
Cohesion: 0.12
Nodes (16): abierto,
  cerradoPendienteArqueo,, apertura, baseInicial, cerrado, cierre, createdAt, diferencia, efectivoContado (+8 more)

### Community 62 - "../../../core/domain/tipo_vehiculo.dart"
Cohesion: 0.12
Nodes (14): ../../../core/domain/tipo_vehiculo.dart, build, crear, createdAt, hashCode, id, operator, placa (+6 more)

### Community 63 - "horario_repository_impl.dart"
Cohesion: 0.11
Nodes (16): ../../../core/network/api_client.dart, ../domain/horario_repository.dart, ../domain/mensualidad_repository.dart, dtos/horario_dto.dart, dtos/horario_page_dto.dart, dtos/mensualidad_dto.dart, dtos/mensualidad_page_dto.dart, crear (+8 more)

### Community 64 - "celdas_screen.dart"
Cohesion: 0.12
Nodes (18): build, celdaGridYaVioDatosProvider, CeldasScreen, _CeldasScreenState, count, createState, dispose, _entradaController (+10 more)

### Community 65 - "turno_cierre_screen_test.dart"
Cohesion: 0.12
Nodes (15): package:intl/date_symbol_data_local.dart, package:parqueadero_app/core/utils/money.dart, package:parqueadero_app/features/turnos/presentation/turno_cierre_screen.dart, main, nbsp, arqueoEnVivo, arqueoFinal, arqueoPendiente (+7 more)

### Community 66 - "turno_cierre_notifier.dart"
Cohesion: 0.10
Nodes (25): abrir_turno_state.dart, ../../data/turno_repository_impl.dart, turnoRepositoryProvider, abrir, AbrirTurnoNotifier, build, AbrirTurnoState, errorMessage (+17 more)

### Community 67 - "package:json_annotation/json_annotation.dart"
Cohesion: 0.12
Nodes (14): celda_dto.dart, accessToken, fromJson, RefreshResponseDto, refreshToken, CeldaPageDto, CeldaPageMetaDto, data (+6 more)

### Community 68 - "celda_list_notifier.dart"
Cohesion: 0.12
Nodes (15): celda_list_state.dart, build, _cargarTicketInfoPorCeldaId, CeldaListNotifier, _isRefreshing, limpiarFiltros, _pollTimer, reemplazarCelda (+7 more)

### Community 69 - "login_screen.dart"
Cohesion: 0.06
Nodes (36): CustomPainter, GlobalKey, build, error, isLoading, LoginController, loginControllerProvider, LoginState (+28 more)

### Community 70 - "auth_repository_test.dart"
Cohesion: 0.08
Nodes (26): dart:convert, DioException, HttpClientAdapter, TokenStorage, MockTokenStorage, package:parqueadero_app/core/network/refresh_interceptor.dart, package:parqueadero_app/core/network/session_events.dart, package:parqueadero_app/features/auth/data/token_storage.dart (+18 more)

### Community 71 - "../domain/ticket.dart"
Cohesion: 0.14
Nodes (13): ../../domain/ticket.dart, Ticket, buscado, errorMessage, isLoading, ticket, error, SalidaStep (+5 more)

### Community 72 - "mensualidad_page_dto.dart"
Cohesion: 0.20
Nodes (9): data, fromJson, MensualidadPageDto, MensualidadPageMetaDto, meta, page, perPage, total (+1 more)

### Community 73 - "turno_dto.dart"
Cohesion: 0.12
Nodes (15): apertura, baseInicial, cierre, createdAt, diferencia, efectivoContado, efectivoEsperado, estado (+7 more)

### Community 74 - "abrir_turno_screen.dart"
Cohesion: 0.12
Nodes (16): abrir_turno_notifier.dart, FormState, tapFeedback, formatEditUpdate, UpperCaseTextFormatter, abrirTurnoNotifierProvider, AbrirTurnoScreen, _AbrirTurnoScreenState (+8 more)

### Community 75 - "ticket_detail_notifier.dart"
Cohesion: 0.14
Nodes (15): buscar_placa_state.dart, ../data/ticket_repository_impl.dart, ticketRepositoryProvider, build, buscar, BuscarPlacaNotifier, BuscarPlacaState, refrescar (+7 more)

### Community 76 - "ticket_repository.dart"
Cohesion: 0.13
Nodes (14): cobro_preview.dart, data, hayMas, listar, obtenerPorId, page, perPage, previsualizarCobro (+6 more)

### Community 77 - "nuevo_usuario_screen.dart"
Cohesion: 0.15
Nodes (14): ../../../core/utils/validators.dart, nuevoUsuarioNotifierProvider, build, createState, dispose, _emailController, _formKey, _nombreController (+6 more)

### Community 78 - "DateTime?"
Cohesion: 0.29
Nodes (6): DateTime?, desglose_item.dart, desglose, horaEntrada, horaSalida, valorTotal

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
Cohesion: 0.17
Nodes (12): celda_accion_state.dart, ../data/celda_repository_impl.dart, ../domain/celda_repository.dart, celdaRepositoryProvider, build, CeldaAccionNotifier, celdaId, _ejecutar (+4 more)

### Community 84 - "mensualidad_filtros_bar.dart"
Cohesion: 0.19
Nodes (12): ../../../../core/widgets/filtros_bar.dart, mensualidadListNotifierProvider, build, build, createState, dispose, initState, MensualidadFiltrosBar (+4 more)

### Community 85 - "celda.dart"
Cohesion: 0.14
Nodes (13): Celda, codigo, createdAt, estado, fromBackend, hashCode, id, mantenimiento (+5 more)

### Community 86 - "mensualidad_dto.dart"
Cohesion: 0.14
Nodes (13): celdaId, createdAt, estadoPago, fechaFin, fechaInicio, fechaPago, fromJson, id (+5 more)

### Community 87 - "mensualidad_list_state.dart"
Cohesion: 0.15
Nodes (12): copyWith, errorMessage, estadoPagoFiltro, hayMas, isLoading, isLoadingMore, mensualidades, page (+4 more)

### Community 88 - "tarifa_dto.dart"
Cohesion: 0.14
Nodes (13): createdAt, fromJson, id, TarifaDto, tipoVehiculo, toDomain, updatedAt, valorMes (+5 more)

### Community 89 - "pago_dto.dart"
Cohesion: 0.12
Nodes (15): ../../domain/pago.dart, createdAt, estado, fecha, fromJson, id, mensualidadId, metodo (+7 more)

### Community 90 - "ticket_list_notifier.dart"
Cohesion: 0.17
Nodes (11): build, cargar, cargarMas, _isLoading, limpiarFiltros, _perPage, refrescar, setEstadoFiltro (+3 more)

### Community 91 - "turno_list_notifier.dart"
Cohesion: 0.14
Nodes (13): build, cargar, cargarMas, _isLoading, limpiarFiltros, _perPage, refrescar, setEstadoFiltro (+5 more)

### Community 92 - "turno_list_state.dart"
Cohesion: 0.14
Nodes (13): copyWith, desdeFiltro, errorMessage, estadoFiltro, hastaFiltro, hayMas, isLoading, isLoadingMore (+5 more)

### Community 93 - "operador_home_dashboard_test.dart"
Cohesion: 0.08
Nodes (24): AuthRepository, login, logout, restoreSession, Material, package:parqueadero_app/features/auth/presentation/widgets/operador_home_dashboard.dart, MockAuthRepository, MockAuthRepository (+16 more)

### Community 94 - "Sistema de diseño — App de Parqueadero"
Cohesion: 0.18
Nodes (10): Antes de dar por terminada una pantalla, Concepto, Escritura de interfaz, La cuadrícula: bahías pintadas, Movimiento, Paleta, Reglas de color innegociables, Rendimiento de la cuadrícula (+2 more)

### Community 95 - "mensualidad_repository_test.dart"
Cohesion: 0.20
Nodes (9): package:parqueadero_app/features/mensualidades/data/mensualidad_repository_impl.dart, dio, _dioError, _jsonResponse, main, _mensualidadJson, MockDio, repository (+1 more)

### Community 96 - "mensualidad_accion_notifier.dart"
Cohesion: 0.17
Nodes (11): ../data/mensualidad_repository_impl.dart, mensualidadRepositoryProvider, build, cancelar, MensualidadAccionNotifier, mensualidadId, errorMessage, isLoading (+3 more)

### Community 97 - "mensualidad_list_notifier.dart"
Cohesion: 0.13
Nodes (14): build, cargar, cargarMas, _isLoading, limpiarFiltros, MensualidadListNotifier, _perPage, reemplazarMensualidad (+6 more)

### Community 98 - "ticket_repository_test.dart"
Cohesion: 0.20
Nodes (9): _celdaJson, dio, _dioError, _jsonResponse, main, repository, requestOptions, _ticketJson (+1 more)

### Community 99 - "turno_activo_indicator.dart"
Cohesion: 0.12
Nodes (16): actionLabel, _Banner, build, createState, _dialogoMostrado, onAction, onVerArqueo, _preguntandoInicio (+8 more)

### Community 100 - "celda_detail_screen_test.dart"
Cohesion: 0.18
Nodes (10): package:parqueadero_app/features/celdas/presentation/celda_detail_screen.dart, authRepository, celda, celdaRepository, main, MockAuthRepository, pumpDetailScreen, pumpDetailScreenConRouter (+2 more)

### Community 101 - "_LoadingSkeletonState"
Cohesion: 0.28
Nodes (9): LoadingSkeleton, _LoadingSkeletonState, TiempoTranscurridoText, _TiempoTranscurridoTextState, _TipoVehiculoDropdown, _TipoVehiculoDropdownState, SingleTickerProviderStateMixin, State (+1 more)

### Community 102 - "celda_detail_screen.dart"
Cohesion: 0.20
Nodes (10): ../celda_accion_notifier.dart, celda_estado_badge.dart, ../celda_list_notifier.dart, ../../../core/widgets/button_spinner.dart, celdaId, celdaId, showCeldaQuickActions, ../../../tickets/presentation/ticket_abierto_de_celda_notifier.dart (+2 more)

### Community 103 - "../domain/celda.dart"
Cohesion: 0.20
Nodes (10): celda_estado_style.dart, ../../domain/celda.dart, EstadoCelda, build, CeldaEstadoBadge, estado, size, build (+2 more)

### Community 104 - "session_notifier.dart"
Cohesion: 0.21
Nodes (11): ../../../core/network/session_events.dart, ../data/auth_repository_impl.dart, sessionEventsProvider, authRepositoryProvider, build, login, logout, _restore (+3 more)

### Community 105 - "_CeldaAccionRapidaSheetState"
Cohesion: 0.32
Nodes (8): build, CeldaAccionRapidaSheet, _CeldaAccionRapidaSheetState, cobroPreviewNotifierProvider, _confirmarYRegistrar, RegistrarSalidaScreen, _RegistrarSalidaScreenState, salidaNotifierProvider

### Community 106 - "turno_repository_impl.dart"
Cohesion: 0.17
Nodes (11): ../domain/turno_repository.dart, dtos/arqueo_turno_dto.dart, dtos/turno_dto.dart, dtos/turno_page_dto.dart, abrir, cerrar, completarArqueo, _dio (+3 more)

### Community 107 - "String?"
Cohesion: 0.09
Nodes (18): ../../domain/vehiculo.dart, errorMessage, isLoading, createdAt, fromJson, id, placa, propietarioNombre (+10 more)

### Community 108 - "horario.dart"
Cohesion: 0.15
Nodes (12): int get, apertura, cierre, createdAt, esVigente, hashCode, Horario, id (+4 more)

### Community 109 - "turno_activo_notifier.dart"
Cohesion: 0.25
Nodes (7): build, cargar, _isLoading, refrescar, TurnoActivoNotifier, TurnoActivoState, turno_activo_state.dart

### Community 110 - "package:dio/dio.dart"
Cohesion: 0.08
Nodes (25): auth_interceptor.dart, Completer, ../config/app_config.dart, ../../features/auth/data/dtos/refresh_response_dto.dart, ../../features/auth/data/token_storage.dart, Interceptor, config, dio (+17 more)

### Community 111 - "usuario_repository.dart"
Cohesion: 0.18
Nodes (10): bool get, actualizar, crear, data, hayMas, listar, page, perPage (+2 more)

### Community 112 - "session_events.dart"
Cohesion: 0.22
Nodes (9): _controller, dispose, emit, events, SessionEvents, SessionEventType, stream, return (+1 more)

### Community 113 - "token_storage.dart"
Cohesion: 0.18
Nodes (10): FlutterSecureStorage, _accessTokenKey, clear, readAccessToken, readRefreshToken, _refreshTokenKey, saveTokens, _storage (+2 more)

### Community 114 - "tiempo_transcurrido_text.dart"
Cohesion: 0.22
Nodes (8): build, createState, dispose, horaEntrada, initState, style, _timer, ../utils/elapsed_time.dart

### Community 115 - "celda_dto.dart"
Cohesion: 0.18
Nodes (10): CeldaDto, codigo, createdAt, estado, fromJson, id, tipoPermitido, toDomain (+2 more)

### Community 116 - "horario_dto.dart"
Cohesion: 0.12
Nodes (15): ../domain/horario.dart, apertura, cierre, createdAt, fromJson, HorarioDto, id, toDomain (+7 more)

### Community 117 - "mensualidad_repository.dart"
Cohesion: 0.18
Nodes (10): cancelar, crear, data, hayMas, listar, MensualidadPageResult, page, perPage (+2 more)

### Community 118 - "tarifa_grupo_card.dart"
Cohesion: 0.22
Nodes (10): Tarifa, tarifaAccionNotifierProvider, build, _confirmarCerrar, _HistoricoRow, tarifa, TarifaGrupoCard, tarifas (+2 more)

### Community 119 - "arqueo_summary_view.dart"
Cohesion: 0.18
Nodes (10): arqueo, ArqueoSummaryView, build, destacado, diferenciaTexto, _Fila, label, valor (+2 more)

### Community 120 - "../../domain/mensualidad.dart"
Cohesion: 0.29
Nodes (6): ../../domain/mensualidad.dart, estado_pago_style.dart, EstadoPagoMensualidad, build, estado, EstadoPagoChip

### Community 121 - "tarifa_simulacion_notifier.dart"
Cohesion: 0.29
Nodes (6): build, limpiar, simular, TarifaSimulacionNotifier, TarifaSimulacionState, tarifa_simulacion_state.dart

### Community 122 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 123 - "usuario_page_dto.dart"
Cohesion: 0.20
Nodes (9): ../../auth/data/dtos/usuario_dto.dart, data, fromJson, meta, page, perPage, total, UsuarioPageDto (+1 more)

### Community 124 - "app_page_transitions.dart"
Cohesion: 0.33
Nodes (5): app_motion.dart, AppPageTransitionsBuilder, Offset, PageTransitionsBuilder, T

### Community 125 - "TipoVehiculo"
Cohesion: 0.33
Nodes (5): carro,
  moto,
  bicicleta,, fromBackend, otro, TipoVehiculo, toBackend

### Community 126 - "Dio"
Cohesion: 0.33
Nodes (6): Dio, MockDio, MockDio, MockDio, MockDio, MockDio

### Community 127 - "recibo_view.dart"
Cohesion: 0.20
Nodes (9): desglose_view.dart, ../../domain/recibo.dart, Recibo, build, kReciboAnchoMm80, _pieStyle, recibo, ReciboView (+1 more)

### Community 128 - "Notifier"
Cohesion: 0.18
Nodes (10): CeldaGridYaVioDatosNotifier, build, confirmarSalida, SalidaNotifier, ticketId, SalidaState, TicketListNotifier, TicketListState (+2 more)

### Community 129 - "horario_page_dto.dart"
Cohesion: 0.20
Nodes (9): horario_dto.dart, data, fromJson, HorarioPageDto, HorarioPageMetaDto, meta, page, perPage (+1 more)

### Community 130 - "material_hero.dart"
Cohesion: 0.33
Nodes (5): build, child, MaterialHero, tag, Widget?

### Community 131 - "List"
Cohesion: 0.13
Nodes (13): build, children, FiltrosBar, data, fromJson, meta, page, perPage (+5 more)

### Community 132 - "ticket_page_dto.dart"
Cohesion: 0.20
Nodes (9): data, fromJson, meta, page, perPage, TicketPageDto, TicketPageMetaDto, total (+1 more)

### Community 133 - "@JsonSerializable"
Cohesion: 0.10
Nodes (20): @JsonSerializable, accessToken, fromJson, LoginResponseDto, refreshToken, usuario, UsuarioDto, EstablecimientoDto (+12 more)

### Community 134 - "nueva_tarifa_notifier.dart"
Cohesion: 0.22
Nodes (8): ../data/tarifa_repository_impl.dart, build, crear, build, tarifaId, nueva_tarifa_state.dart, tarifa_accion_state.dart, ../tarifa_list_notifier.dart

### Community 135 - "validators.dart"
Cohesion: 0.22
Nodes (8): _emailRegex, emailValidator, hasMatch, placaValidator, requiredError, requiredIntegerValidator, requiredValidator, tryParse

### Community 136 - "../../../../core/utils/tipo_vehiculo_label.dart"
Cohesion: 0.25
Nodes (8): ../../../../core/utils/tipo_vehiculo_label.dart, ../../domain/tarifa.dart, tarifaListNotifierProvider, build, build, TarifaFiltrosBar, Route /tarifas/nueva, main

### Community 137 - "AGENTS.md — parqueadero_app"
Cohesion: 0.40
Nodes (4): AGENTS.md — parqueadero_app, No negociable, Relación con el otro proyecto, Verificación antes de entregar

### Community 138 - "_"
Cohesion: 0.29
Nodes (8): _, AppColors, asfalto, concreto, demarcacion, linea, tinta, verdeSenal

### Community 139 - "_"
Cohesion: 0.29
Nodes (8): _, AppSpacing, gutter, lg, md, sm, xl, xs

### Community 140 - "_"
Cohesion: 0.29
Nodes (8): Usuario, _, authenticated, checking, SessionStatus, status, unauthenticated, usuario

### Community 141 - "celda_repository.dart"
Cohesion: 0.40
Nodes (4): celda.dart, listarTodas, marcarMantenimiento, volverALibre

### Community 142 - "_"
Cohesion: 0.33
Nodes (7): _, AppMotion, curve, effective, fast, medium, slow

### Community 143 - "animated_count_text.dart"
Cohesion: 0.29
Nodes (6): AnimatedCountText, build, style, value, TextStyle?, ../theme/app_motion.dart

### Community 144 - "tarifa_list_notifier.dart"
Cohesion: 0.22
Nodes (9): tarifaRepositoryProvider, cerrar, build, _isLoading, refrescar, setTipoFiltro, TarifaListNotifier, TarifaListState (+1 more)

### Community 145 - "tarifa_list_state.dart"
Cohesion: 0.29
Nodes (6): copyWith, errorMessage, isLoading, tarifas, tipoFiltro, _unset

### Community 146 - "cobro_preview_state.dart"
Cohesion: 0.22
Nodes (8): CobroPreview, CobroPreviewNotifier, CobroPreviewState, copyWith, error, esTerminal, isLoading, preview

### Community 149 - "../../domain/turno.dart"
Cohesion: 0.12
Nodes (16): ../../domain/turno.dart, EstadoTurno, Turno, errorMessage, isLoading, turno, build, estado (+8 more)

### Community 150 - "_"
Cohesion: 0.40
Nodes (6): _, AppBreakpoints, contentMaxWidth, gridMaxWidth, mobile, tablet

### Community 151 - "static const"
Cohesion: 0.40
Nodes (6): _, AppElevation, flat, low, raised, static const

### Community 153 - "vigencia_chip.dart"
Cohesion: 0.33
Nodes (5): VigenciaMensualidad, build, vigencia, VigenciaChip, vigencia_style.dart

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

### Community 160 - "ticket_abierto_de_celda_notifier.dart"
Cohesion: 0.20
Nodes (8): build, buscar, celdaId, TicketAbiertoDeCeldaNotifier, errorMessage, isLoading, TicketAbiertoDeCeldaState, ticket_abierto_de_celda_state.dart

### Community 162 - "elapsed_time.dart"
Cohesion: 0.50
Nodes (3): formatElapsed, horas, minutos

### Community 164 - "TarifaAccionNotifier"
Cohesion: 0.40
Nodes (4): TarifaAccionNotifier, errorMessage, isLoading, TarifaAccionState

## Knowledge Gaps
- **1656 isolated node(s):** `AppConfig`, `apiBaseUrl`, `appConfigProvider`, `fromEnvironment`, `otro` (+1651 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1956 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `TarifaRepository` connect `Mock` to `tarifa_repository_impl.dart`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Why does `TipoVehiculo` connect `TipoVehiculo` to `nueva_mensualidad_screen.dart`, `registrar_entrada_screen.dart`, `tarifa.dart`, `tarifa_list_state.dart`, `celda_list_state.dart`, `celda.dart`, `tarifa_grupo_card.dart`, `nueva_tarifa_screen.dart`, `recibo.dart`, `../../../core/domain/tipo_vehiculo.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Why does `_` connect `_` to `package:flutter/material.dart`, `static const`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **What connects `AppConfig`, `apiBaseUrl`, `appConfigProvider` to the rest of the system?**
  _1656 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `MockAuthRepository` be split into smaller, more focused modules?**
  _Cohesion score 0.02582398912674142 - nodes in this community are weakly interconnected._
- **Should `usuario_detail_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05142857142857143 - nodes in this community are weakly interconnected._
- **Should `package:flutter_test/flutter_test.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05152394775036284 - nodes in this community are weakly interconnected._