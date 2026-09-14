# Graph Report - parqueadero_app  (2026-09-14)

## Corpus Check
- 322 files · ~97,884 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3099 nodes · 5480 edges · 182 communities (177 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a926f9cf`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- operador_home_dashboard_test.dart
- package:flutter_riverpod/flutter_riverpod.dart
- turno_kpis_view.dart
- turno_cierre_screen_test.dart
- app_router.dart
- package:parqueadero_app/features/auth/domain/usuario.dart
- nueva_mensualidad_screen_test.dart
- horario_accion_notifier_test.dart
- celdas_screen_test.dart
- ticket_detail_notifier.dart
- tarifa_grupo_card.dart
- horarios_screen.dart
- api_exception.dart
- Mock
- sessionNotifierProvider
- celda_card_test.dart
- auth_repository.dart
- recibo_dto.dart
- celda_card.dart
- ticket.dart
- ticket_dto.dart
- celda_list_state.dart
- package:go_router/go_router.dart
- ticket_list_state.dart
- zona_header.dart
- dashboard_metric_card.dart
- ../../../core/network/api_exception.dart
- package:json_annotation/json_annotation.dart
- nueva_tarifa_screen.dart
- recibo.dart
- tarifa_repository_impl.dart
- nuevo_horario_screen.dart
- ticket_filtros_bar.dart
- turno_filtros_bar.dart
- ticket_repository_impl.dart
- package:flutter/material.dart
- operador_home_dashboard.dart
- List
- nueva_mensualidad_screen.dart
- registrar_entrada_screen.dart
- pago.dart
- turnoRepositoryProvider
- StatelessWidget
- _
- usuario.dart
- tarifa.dart
- package:parqueadero_app/core/network/api_exception.dart
- mensualidad.dart
- ticket_list_notifier.dart
- arqueo_turno_dto.dart
- celda_accion_rapida_sheet_test.dart
- registrar_salida_screen_test.dart
- int?
- build
- buscar_placa_screen.dart
- package:dio/dio.dart
- mensualidad_page_dto.dart
- tarifa_simulacion_notifier.dart
- registrar_entrada_screen_test.dart
- desglose_item.dart
- arqueo_turno.dart
- turno.dart
- ../../../core/domain/tipo_vehiculo.dart
- mensualidad_filtros_bar.dart
- celdas_screen.dart
- turno_cierre_screen.dart
- turno_activo_indicator.dart
- horario_list_notifier.dart
- celda_list_notifier.dart
- login_screen.dart
- auth_repository_test.dart
- ../../domain/ticket.dart
- package:flutter_test/flutter_test.dart
- turno_dto.dart
- desglose_view.dart
- String?
- ticket_repository.dart
- ConsumerState
- DateTime
- nuevo_usuario_screen.dart
- empty_state.dart
- turno_repository.dart
- celda_detail_screen.dart
- celda_detail_screen_test.dart
- vigencia_chip.dart
- celda.dart
- mensualidad_dto.dart
- mensualidad_list_state.dart
- tarifa_dto.dart
- pago_dto.dart
- registrar_salida_screen.dart
- turno_list_notifier.dart
- turno_list_state.dart
- placa_tipo.dart
- Sistema de diseño — App de Parqueadero
- api_client.dart
- login_screen_test.dart
- mensualidad_list_notifier.dart
- turno_cierre_state.dart
- turno_cierre_notifier.dart
- horario_repository_test.dart
- abrir_turno_screen.dart
- turno_repository_test.dart
- ../domain/celda.dart
- session_notifier.dart
- turno_page_dto.dart
- turno_repository_impl.dart
- vehiculo_dto.dart
- horario.dart
- tarifa_list_state.dart
- nueva_tarifa_screen_test.dart
- usuario_repository.dart
- tarifas_screen_test.dart
- token_storage.dart
- nueva_tarifa_notifier_test.dart
- celda_dto.dart
- tiempo_transcurrido_text.dart
- mensualidad_repository.dart
- loading_skeleton.dart
- salida_notifier.dart
- estado_pago_chip.dart
- cobro_preview_notifier.dart
- manifest.json
- usuario_page_dto.dart
- ticket_abierto_de_celda_notifier.dart
- TarifaRepository
- ticket_page_dto.dart
- ../../../core/theme/app_spacing.dart
- horario_accion_notifier.dart
- horarios_screen_test.dart
- Dio
- @JsonSerializable
- refresh_interceptor.dart
- dart:async
- tarifa_list_notifier.dart
- validators.dart
- nuevo_horario_screen_test.dart
- AGENTS.md
- _
- _
- ticket_repository_test.dart
- mensualidad_repository_test.dart
- _
- mensualidad_repository_impl.dart
- recibo_view.dart
- app_page_transitions.dart
- tarifaListNotifierProvider
- parqueadero_app
- State
- usuario_repository_test.dart
- _
- _
- horario_repository_impl.dart
- HorarioRepository
- seleccionar_hora.dart
- tarifa_repository.dart
- home_screen.dart
- _
- animated_count_text.dart
- tarifa_list_notifier_test.dart
- tarifa_accion_notifier_test.dart
- _
- elapsed_time.dart
- nuevo_horario_notifier.dart
- ../../domain/mensualidad.dart
- horario_repository.dart
- celda_leyenda.dart
- print_launcher_web.dart
- rol_usuario_label.dart
- material_hero.dart
- print_launcher.dart
- print_launcher_stub.dart
- static const
- build
- turno_detail_notifier.dart
- tarifa_accion_notifier.dart
- turno_estado_chip.dart
- TipoVehiculo
- _
- Notifier
- ticket_estado_chip.dart
- AbrirTurnoNotifier

## God Nodes (most connected - your core abstractions)
1. `sessionNotifierProvider` - 48 edges
2. `AuthRepository` - 34 edges
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

## Communities (182 total, 5 thin omitted)

### Community 0 - "operador_home_dashboard_test.dart"
Cohesion: 0.03
Nodes (98): Icon, Material, MockTurnoRepository, package:parqueadero_app/features/auth/data/auth_repository_impl.dart, package:parqueadero_app/features/auth/domain/auth_repository.dart, package:parqueadero_app/features/auth/presentation/session_notifier.dart, package:parqueadero_app/features/auth/presentation/session_state.dart, package:parqueadero_app/features/auth/presentation/widgets/operador_home_dashboard.dart (+90 more)

### Community 1 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.06
Nodes (43): ../../../auth/domain/usuario.dart, ../../../../core/utils/rol_usuario_label.dart, ../data/usuario_repository_impl.dart, build, crear, NuevoUsuarioNotifier, NuevoUsuarioState, build (+35 more)

### Community 2 - "turno_kpis_view.dart"
Cohesion: 0.08
Nodes (23): Duration, ahora, arqueo, build, calcular, child, descuadrePorcentaje, duracion (+15 more)

### Community 3 - "turno_cierre_screen_test.dart"
Cohesion: 0.07
Nodes (26): package:intl/date_symbol_data_local.dart, package:parqueadero_app/core/utils/money.dart, package:parqueadero_app/core/widgets/detail_skeleton.dart, package:parqueadero_app/features/tickets/presentation/buscar_placa_screen.dart, package:parqueadero_app/features/turnos/presentation/turno_cierre_screen.dart, main, nbsp, authRepository (+18 more)

### Community 4 - "app_router.dart"
Cohesion: 0.05
Nodes (42): ChangeNotifier, core/config/app_config.dart, core/router/app_router.dart, core/theme/app_theme.dart, ../../features/auth/presentation/home_screen.dart, ../../features/auth/presentation/login_screen.dart, ../../features/auth/presentation/session_notifier.dart, ../../features/auth/presentation/session_state.dart (+34 more)

### Community 5 - "package:parqueadero_app/features/auth/domain/usuario.dart"
Cohesion: 0.04
Nodes (70): UsuarioRepository, MockAuthRepository, MockUsuarioRepository, package:parqueadero_app/core/widgets/acceso_restringido.dart, package:parqueadero_app/features/auth/domain/usuario.dart, package:parqueadero_app/features/turnos/presentation/turnos_historial_screen.dart, package:parqueadero_app/features/turnos/presentation/widgets/turno_list_item.dart, package:parqueadero_app/features/usuarios/data/usuario_repository_impl.dart (+62 more)

### Community 6 - "nueva_mensualidad_screen_test.dart"
Cohesion: 0.17
Nodes (11): package:parqueadero_app/features/mensualidades/presentation/nueva_mensualidad_screen.dart, authRepository, celda, celdaRepository, main, mensualidadRepository, MockAuthRepository, MockTicketRepository (+3 more)

### Community 7 - "horario_accion_notifier_test.dart"
Cohesion: 0.15
Nodes (14): MockHorarioRepository, package:parqueadero_app/features/horarios/domain/horario.dart, package:parqueadero_app/features/horarios/domain/horario_repository.dart, package:parqueadero_app/features/horarios/presentation/horario_accion_notifier.dart, package:parqueadero_app/features/horarios/presentation/horario_list_notifier.dart, container, horario, horarioRepository (+6 more)

### Community 8 - "celdas_screen_test.dart"
Cohesion: 0.04
Nodes (66): MockTicketRepository, package:parqueadero_app/core/widgets/animated_count_text.dart, package:parqueadero_app/core/widgets/empty_state.dart, package:parqueadero_app/core/widgets/error_state.dart, package:parqueadero_app/features/celdas/presentation/celdas_screen.dart, package:parqueadero_app/features/celdas/presentation/widgets/celda_grid_skeleton.dart, package:parqueadero_app/features/celdas/presentation/widgets/celda_leyenda.dart, package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart (+58 more)

### Community 9 - "ticket_detail_notifier.dart"
Cohesion: 0.14
Nodes (15): buscar_placa_state.dart, ../data/ticket_repository_impl.dart, ticketRepositoryProvider, build, buscar, BuscarPlacaNotifier, BuscarPlacaState, refrescar (+7 more)

### Community 10 - "tarifa_grupo_card.dart"
Cohesion: 0.11
Nodes (20): tarifaAccionNotifierProvider, build, _confirmarCerrar, createState, dispose, _editar, _EditarTarifaDialog, _EditarTarifaDialogState (+12 more)

### Community 11 - "horarios_screen.dart"
Cohesion: 0.11
Nodes (18): horario_accion_notifier.dart, _apertura, _cierre, createState, _editar, _elegirApertura, _elegirCierre, enabled (+10 more)

### Community 12 - "api_exception.dart"
Cohesion: 0.15
Nodes (12): DioExceptionType, ApiErrorDetail, code, details, field, fromDioException, fromJson, fromResponse (+4 more)

### Community 13 - "Mock"
Cohesion: 0.05
Nodes (64): celda.dart, AuthRepository, CeldaRepository, listarTodas, marcarMantenimiento, volverALibre, MensualidadRepositoryImpl, MensualidadRepository (+56 more)

### Community 14 - "sessionNotifierProvider"
Cohesion: 0.19
Nodes (22): ConsumerWidget, sessionNotifierProvider, AdminHomeDashboard, _CeldasLibresCard, OperadorHomeDashboard, celdaAccionNotifierProvider, build, CeldaDetailScreen (+14 more)

### Community 15 - "celda_card_test.dart"
Cohesion: 0.04
Nodes (65): MockCeldaRepository, package:parqueadero_app/features/auth/presentation/widgets/admin_home_dashboard.dart, package:parqueadero_app/features/celdas/data/celda_repository_impl.dart, package:parqueadero_app/features/celdas/domain/celda.dart, package:parqueadero_app/features/celdas/domain/celda_repository.dart, package:parqueadero_app/features/celdas/presentation/celda_accion_notifier.dart, package:parqueadero_app/features/celdas/presentation/celda_list_notifier.dart, package:parqueadero_app/features/celdas/presentation/widgets/celda_accion_rapida_sheet.dart (+57 more)

### Community 16 - "auth_repository.dart"
Cohesion: 0.40
Nodes (4): login, logout, restoreSession, usuario.dart

### Community 17 - "recibo_dto.dart"
Cohesion: 0.07
Nodes (26): celda, ciudad, consecutivo, desglose, direccion, establecimiento, fechaEmision, fromJson (+18 more)

### Community 18 - "celda_card.dart"
Cohesion: 0.09
Nodes (21): celda_accion_rapida_sheet.dart, celda_quick_actions_sheet.dart, ../../../../core/theme/app_elevation.dart, ../../../../core/theme/app_radius.dart, ../../../../core/utils/haptics.dart, ../../../core/widgets/loading_skeleton.dart, _abrirAccionRapida, celdaId (+13 more)

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

### Community 22 - "package:go_router/go_router.dart"
Cohesion: 0.08
Nodes (24): ../../../../core/utils/bogota_time.dart, ../../../../core/utils/money.dart, ../../../../core/widgets/material_hero.dart, diferencia_texto.dart, estado_pago_chip.dart, Usuario, Mensualidad, build (+16 more)

### Community 23 - "ticket_list_state.dart"
Cohesion: 0.14
Nodes (13): copyWith, desdeFiltro, errorMessage, estadoFiltro, hastaFiltro, hayMas, isLoading, isLoadingMore (+5 more)

### Community 24 - "zona_header.dart"
Cohesion: 0.13
Nodes (14): ../../../../core/theme/app_motion.dart, ../../../../core/widgets/animated_count_text.dart, ancho, _BarraOcupacion, borde, build, color, libres (+6 more)

### Community 25 - "dashboard_metric_card.dart"
Cohesion: 0.08
Nodes (24): animated_count_text.dart, build, DashboardActionGroup, DashboardActionItem, _DashboardActionRow, icon, item, items (+16 more)

### Community 26 - "../../../core/network/api_exception.dart"
Cohesion: 0.15
Nodes (11): ../../../core/network/api_exception.dart, CobroPreview, copyWith, error, esTerminal, isLoading, preview, error (+3 more)

### Community 27 - "package:json_annotation/json_annotation.dart"
Cohesion: 0.12
Nodes (14): horario_dto.dart, accessToken, fromJson, RefreshResponseDto, refreshToken, data, fromJson, HorarioPageDto (+6 more)

### Community 28 - "nueva_tarifa_screen.dart"
Cohesion: 0.09
Nodes (25): nuevaTarifaNotifierProvider, build, createState, _debounce, dispose, _duracionesPreset, duracionLabel, _duracionMinutos (+17 more)

### Community 29 - "recibo.dart"
Cohesion: 0.08
Nodes (24): celda, ciudad, consecutivo, desglose, direccion, Establecimiento, fechaEmision, horaEntrada (+16 more)

### Community 30 - "tarifa_repository_impl.dart"
Cohesion: 0.18
Nodes (10): ../domain/tarifa_repository.dart, dtos/tarifa_dto.dart, dtos/tarifa_page_dto.dart, actualizar, cerrar, crear, _dio, listarTodas (+2 more)

### Community 31 - "nuevo_horario_screen.dart"
Cohesion: 0.10
Nodes (20): nuevoHorarioNotifierProvider, _apertura, build, _cierre, createState, _elegirApertura, _elegirCierre, enabled (+12 more)

### Community 32 - "ticket_filtros_bar.dart"
Cohesion: 0.13
Nodes (16): formatBogota, toBogota, formatMoney, ticketListNotifierProvider, build, TicketsHistorialScreen, build, createState (+8 more)

### Community 33 - "turno_filtros_bar.dart"
Cohesion: 0.13
Nodes (18): turnoListNotifierProvider, build, TurnosHistorialScreen, build, createState, _elegirRango, onChanged, _OperadorDropdown (+10 more)

### Community 34 - "ticket_repository_impl.dart"
Cohesion: 0.13
Nodes (13): desglose_item_dto.dart, ../domain/cobro_preview.dart, ../domain/ticket_repository.dart, dtos/cobro_preview_dto.dart, dtos/ticket_dto.dart, dtos/ticket_page_dto.dart, cobroPreviewFromJson, _dio (+5 more)

### Community 35 - "package:flutter/material.dart"
Cohesion: 0.08
Nodes (21): empty_state.dart, AccesoRestringido, build, build, DetailSkeleton, lineas, build, error (+13 more)

### Community 36 - "operador_home_dashboard.dart"
Cohesion: 0.09
Nodes (22): ../../../../core/theme/app_breakpoints.dart, ../../../../core/theme/app_colors.dart, ../../../../core/widgets/dashboard_action_group.dart, ../../../../core/widgets/dashboard_metric_card.dart, build, error, isLoading, LoginController (+14 more)

### Community 37 - "List"
Cohesion: 0.13
Nodes (13): celda_dto.dart, build, children, FiltrosBar, CeldaPageDto, CeldaPageMetaDto, data, fromJson (+5 more)

### Community 38 - "nueva_mensualidad_screen.dart"
Cohesion: 0.09
Nodes (20): ../../celdas/domain/celda.dart, DateTimeRange?, tapFeedback, formatEditUpdate, UpperCaseTextFormatter, _celda, createState, dispose (+12 more)

### Community 39 - "registrar_entrada_screen.dart"
Cohesion: 0.10
Nodes (19): ../../celdas/presentation/widgets/celda_estado_badge.dart, ../../../core/utils/placa_tipo.dart, celdaId, _codigosCeldaEspecifica, createState, dispose, enabled, _enviando (+11 more)

### Community 40 - "pago.dart"
Cohesion: 0.09
Nodes (21): efectivo,
  tarjeta,, anulado, createdAt, estado, EstadoPago, fecha, fromBackend, hashCode (+13 more)

### Community 41 - "turnoRepositoryProvider"
Cohesion: 0.29
Nodes (10): turnoRepositoryProvider, abrir, turnoActivoNotifierProvider, cerrar, completarArqueo, TurnoCierreNotifier, TurnoCierreState, _preguntarIniciarTurno (+2 more)

### Community 42 - "StatelessWidget"
Cohesion: 0.06
Nodes (38): class, _Formulario, _MarcaPanel, _buscando, _buscar, celdaId, child, createState (+30 more)

### Community 43 - "_"
Cohesion: 0.10
Nodes (21): app_colors.dart, app_elevation.dart, app_page_transitions.dart, app_radius.dart, app_spacing.dart, _, AppTheme, _colorScheme (+13 more)

### Community 44 - "usuario.dart"
Cohesion: 0.05
Nodes (40): admin,, bool?, activo, baseInicialTurno, createdAt, email, fromBackend, hashCode (+32 more)

### Community 45 - "tarifa.dart"
Cohesion: 0.13
Nodes (14): createdAt, esVigente, hashCode, id, operator, Tarifa, tipoVehiculo, updatedAt (+6 more)

### Community 46 - "package:parqueadero_app/core/network/api_exception.dart"
Cohesion: 0.09
Nodes (22): package:fake_async/fake_async.dart, package:parqueadero_app/core/network/api_exception.dart, package:parqueadero_app/features/horarios/presentation/nuevo_horario_notifier.dart, package:parqueadero_app/features/tarifas/presentation/tarifa_simulacion_notifier.dart, package:parqueadero_app/features/tickets/domain/cobro_preview.dart, package:parqueadero_app/features/tickets/presentation/cobro_preview_notifier.dart, ProviderContainer, container (+14 more)

### Community 47 - "mensualidad.dart"
Cohesion: 0.10
Nodes (19): cancelada, celdaId, createdAt, diasPorVencerDefault, estadoPago, fechaFin, fechaInicio, fechaPago (+11 more)

### Community 48 - "ticket_list_notifier.dart"
Cohesion: 0.17
Nodes (11): build, cargar, cargarMas, _isLoading, limpiarFiltros, _perPage, refrescar, setEstadoFiltro (+3 more)

### Community 49 - "arqueo_turno_dto.dart"
Cohesion: 0.09
Nodes (21): apertura, ArqueoTurnoDto, baseInicial, cierre, diferencia, efectivo, efectivoContado, efectivoEsperado (+13 more)

### Community 50 - "celda_accion_rapida_sheet_test.dart"
Cohesion: 0.11
Nodes (17): ConstrainedBox, package:parqueadero_app/core/domain/tipo_vehiculo.dart, package:parqueadero_app/core/theme/app_typography.dart, package:parqueadero_app/core/utils/placa_tipo.dart, package:parqueadero_app/core/widgets/error_banner.dart, main, authRepository, establecimiento (+9 more)

### Community 51 - "registrar_salida_screen_test.dart"
Cohesion: 0.07
Nodes (27): package:parqueadero_app/features/tickets/data/dtos/desglose_item_dto.dart, package:parqueadero_app/features/tickets/data/dtos/recibo_dto.dart, package:parqueadero_app/features/tickets/domain/desglose_item.dart, package:parqueadero_app/features/tickets/domain/pago.dart, package:parqueadero_app/features/tickets/presentation/registrar_salida_screen.dart, Route /salida, main, _establecimientoJson (+19 more)

### Community 52 - "int?"
Cohesion: 0.12
Nodes (15): int?, activo, baseInicialTurno, createdAt, email, fromJson, id, nombre (+7 more)

### Community 53 - "build"
Cohesion: 0.20
Nodes (12): build, build, registrarEntradaNotifierProvider, build, Route /horarios, Route /mensualidades, Route /tarifas, Route /tickets (+4 more)

### Community 54 - "buscar_placa_screen.dart"
Cohesion: 0.13
Nodes (17): buscar_placa_notifier.dart, ../../../../core/utils/elapsed_time.dart, ../../../core/utils/upper_case_text_formatter.dart, buscarPlacaNotifierProvider, build, _buscar, BuscarPlacaScreen, _BuscarPlacaScreenState (+9 more)

### Community 55 - "package:dio/dio.dart"
Cohesion: 0.12
Nodes (16): ../domain/auth_repository.dart, dtos/login_response_dto.dart, dtos/usuario_dto.dart, onRequest, _tokenStorage, AuthRepositoryImpl, _dio, login (+8 more)

### Community 56 - "mensualidad_page_dto.dart"
Cohesion: 0.20
Nodes (9): data, fromJson, MensualidadPageDto, MensualidadPageMetaDto, meta, page, perPage, total (+1 more)

### Community 57 - "tarifa_simulacion_notifier.dart"
Cohesion: 0.29
Nodes (6): build, limpiar, simular, TarifaSimulacionNotifier, TarifaSimulacionState, tarifa_simulacion_state.dart

### Community 58 - "registrar_entrada_screen_test.dart"
Cohesion: 0.11
Nodes (17): DropdownButtonFormField, package:parqueadero_app/features/tickets/presentation/registrar_entrada_screen.dart, Route /entrada, authRepository, celdaLibre, celdaRepository, main, operador (+9 more)

### Community 59 - "desglose_item.dart"
Cohesion: 0.13
Nodes (17): bloqueNumero, DesgloseBloque, DesgloseItem, DesgloseManual, DesgloseMensualidad, dia, fin, fromBackend (+9 more)

### Community 60 - "arqueo_turno.dart"
Cohesion: 0.11
Nodes (17): apertura, baseInicial, cierre, diferencia, efectivo, efectivoContado, efectivoEsperado, estado (+9 more)

### Community 61 - "turno.dart"
Cohesion: 0.11
Nodes (18): abierto,
  cerradoPendienteArqueo,, apertura, baseInicial, cerrado, cierre, createdAt, diferencia, efectivoContado (+10 more)

### Community 62 - "../../../core/domain/tipo_vehiculo.dart"
Cohesion: 0.12
Nodes (14): ../../../core/domain/tipo_vehiculo.dart, build, crear, createdAt, hashCode, id, operator, placa (+6 more)

### Community 63 - "mensualidad_filtros_bar.dart"
Cohesion: 0.08
Nodes (28): ../../../../core/widgets/filtros_bar.dart, ../data/mensualidad_repository_impl.dart, mensualidadRepositoryProvider, build, cancelar, MensualidadAccionNotifier, mensualidadAccionNotifierProvider, mensualidadId (+20 more)

### Community 64 - "celdas_screen.dart"
Cohesion: 0.12
Nodes (19): build, celdaGridYaVioDatosProvider, CeldasScreen, _CeldasScreenState, count, createState, dispose, _entradaController (+11 more)

### Community 65 - "turno_cierre_screen.dart"
Cohesion: 0.07
Nodes (27): ../../../core/widgets/error_banner.dart, ../../domain/turno.dart, Turno, build, cargar, _isLoading, refrescar, TurnoActivoNotifier (+19 more)

### Community 66 - "turno_activo_indicator.dart"
Cohesion: 0.13
Nodes (14): actionLabel, _Banner, build, createState, _dialogoMostrado, onAction, onVerArqueo, _preguntandoInicio (+6 more)

### Community 67 - "horario_list_notifier.dart"
Cohesion: 0.14
Nodes (15): ../data/horario_repository_impl.dart, horario_list_state.dart, horarioRepositoryProvider, cerrar, build, HorarioListNotifier, horarioListNotifierProvider, _isLoading (+7 more)

### Community 68 - "celda_list_notifier.dart"
Cohesion: 0.07
Nodes (28): celda_accion_state.dart, ../celda_list_notifier.dart, celda_list_state.dart, ../data/celda_repository_impl.dart, ../domain/celda_repository.dart, celdaRepositoryProvider, build, CeldaAccionNotifier (+20 more)

### Community 69 - "login_screen.dart"
Cohesion: 0.08
Nodes (25): GlobalKey, loginControllerProvider, _alturaMarcaCompacta, build, createState, _demarcacionBorder, dispose, _emailController (+17 more)

### Community 70 - "auth_repository_test.dart"
Cohesion: 0.08
Nodes (23): dart:convert, DioException, HttpClientAdapter, MockTokenStorage, package:parqueadero_app/core/network/refresh_interceptor.dart, package:parqueadero_app/core/network/session_events.dart, package:parqueadero_app/features/auth/data/token_storage.dart, dio (+15 more)

### Community 71 - "../../domain/ticket.dart"
Cohesion: 0.11
Nodes (16): ../../domain/ticket.dart, Ticket, buscado, errorMessage, isLoading, ticket, build, registrar (+8 more)

### Community 72 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.05
Nodes (48): Hero, MockMensualidadRepository, package:flutter_test/flutter_test.dart, package:mocktail/mocktail.dart, package:parqueadero_app/core/theme/app_theme.dart, package:parqueadero_app/core/utils/elapsed_time.dart, package:parqueadero_app/core/utils/validators.dart, package:parqueadero_app/features/mensualidades/data/mensualidad_repository_impl.dart (+40 more)

### Community 73 - "turno_dto.dart"
Cohesion: 0.11
Nodes (17): apertura, baseInicial, cierre, createdAt, diferencia, efectivoContado, efectivoEsperado, estado (+9 more)

### Community 74 - "desglose_view.dart"
Cohesion: 0.15
Nodes (11): ../../../../core/theme/app_typography.dart, ../../domain/desglose_item.dart, desgloseFromJson, map, build, desglose, DesgloseView, _fila (+3 more)

### Community 75 - "String?"
Cohesion: 0.10
Nodes (17): errorMessage, isLoading, apertura, cierre, createdAt, fromJson, HorarioDto, id (+9 more)

### Community 76 - "ticket_repository.dart"
Cohesion: 0.13
Nodes (14): cobro_preview.dart, data, hayMas, listar, obtenerPorId, page, perPage, previsualizarCobro (+6 more)

### Community 77 - "ConsumerState"
Cohesion: 0.11
Nodes (27): ConsumerState, ConsumerStatefulWidget, build, CeldaAccionRapidaSheet, _CeldaAccionRapidaSheetState, NuevaMensualidadScreen, cobroPreviewNotifierProvider, build (+19 more)

### Community 78 - "DateTime"
Cohesion: 0.18
Nodes (9): DateTime, desglose_item.dart, build, RelojNotifier, _timer, desglose, horaEntrada, horaSalida (+1 more)

### Community 79 - "nuevo_usuario_screen.dart"
Cohesion: 0.15
Nodes (14): ../../../core/utils/validators.dart, nuevoUsuarioNotifierProvider, build, createState, dispose, _emailController, _formKey, _nombreController (+6 more)

### Community 80 - "empty_state.dart"
Cohesion: 0.15
Nodes (11): actionLabel, build, EmptyState, icon, message, onAction, build, ErrorState (+3 more)

### Community 81 - "turno_repository.dart"
Cohesion: 0.14
Nodes (13): arqueo_turno.dart, abrir, cerrar, completarArqueo, data, hayMas, listar, obtenerArqueo (+5 more)

### Community 82 - "celda_detail_screen.dart"
Cohesion: 0.18
Nodes (10): ../celda_accion_notifier.dart, celda_estado_badge.dart, ../../../../core/utils/tipo_vehiculo_label.dart, ../../../core/widgets/button_spinner.dart, celdaId, celdaId, showCeldaQuickActions, ../../../tickets/presentation/ticket_abierto_de_celda_notifier.dart (+2 more)

### Community 83 - "celda_detail_screen_test.dart"
Cohesion: 0.17
Nodes (11): package:parqueadero_app/features/celdas/presentation/celda_detail_screen.dart, authRepository, celda, celdaRepository, main, MockAuthRepository, MockTicketRepository, pumpDetailScreen (+3 more)

### Community 84 - "vigencia_chip.dart"
Cohesion: 0.33
Nodes (5): VigenciaMensualidad, build, vigencia, VigenciaChip, vigencia_style.dart

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

### Community 90 - "registrar_salida_screen.dart"
Cohesion: 0.09
Nodes (23): cobro_preview_notifier.dart, ../../../core/utils/print/print_launcher.dart, ../../../core/widgets/tiempo_transcurrido_text.dart, ticketId, createState, dispose, _metodo, montoRecibido (+15 more)

### Community 91 - "turno_list_notifier.dart"
Cohesion: 0.14
Nodes (13): build, cargar, cargarMas, _isLoading, limpiarFiltros, _perPage, refrescar, setEstadoFiltro (+5 more)

### Community 92 - "turno_list_state.dart"
Cohesion: 0.14
Nodes (13): copyWith, desdeFiltro, errorMessage, estadoFiltro, hastaFiltro, hayMas, isLoading, isLoadingMore (+5 more)

### Community 93 - "placa_tipo.dart"
Cohesion: 0.18
Nodes (9): ../domain/tipo_vehiculo.dart, null, _placaCarroRegex, _placaMotoActualRegex, _placaMotoAntiguaRegex, tipoVehiculoDePlaca, tipoVehiculoIcon, tipoVehiculoLabel (+1 more)

### Community 94 - "Sistema de diseño — App de Parqueadero"
Cohesion: 0.18
Nodes (10): Antes de dar por terminada una pantalla, Concepto, Escritura de interfaz, La cuadrícula: bahías pintadas, Movimiento, Paleta, Reglas de color innegociables, Rendimiento de la cuadrícula (+2 more)

### Community 95 - "api_client.dart"
Cohesion: 0.18
Nodes (10): auth_interceptor.dart, ../config/app_config.dart, ../../features/auth/data/token_storage.dart, config, dio, dioProvider, sessionEvents, tokenStorage (+2 more)

### Community 96 - "login_screen_test.dart"
Cohesion: 0.05
Nodes (37): BoxDecoration, Container, dart:math, ElevatedButton, package:parqueadero_app/core/theme/app_breakpoints.dart, package:parqueadero_app/core/theme/app_colors.dart, package:parqueadero_app/core/theme/status_style.dart, package:parqueadero_app/features/auth/presentation/login_screen.dart (+29 more)

### Community 97 - "mensualidad_list_notifier.dart"
Cohesion: 0.13
Nodes (14): build, cargar, cargarMas, _isLoading, limpiarFiltros, MensualidadListNotifier, _perPage, reemplazarMensualidad (+6 more)

### Community 98 - "turno_cierre_state.dart"
Cohesion: 0.20
Nodes (9): ../../domain/arqueo_turno.dart, ArqueoTurno, error, resultado, step, TurnoCierreStep, arqueo, errorMessage (+1 more)

### Community 99 - "turno_cierre_notifier.dart"
Cohesion: 0.25
Nodes (7): abrir_turno_state.dart, ../../data/turno_repository_impl.dart, build, build, turnoId, ../turno_activo_notifier.dart, turno_cierre_state.dart

### Community 100 - "horario_repository_test.dart"
Cohesion: 0.20
Nodes (9): package:parqueadero_app/features/horarios/data/horario_repository_impl.dart, dio, _dioError, _horarioJson, _jsonResponse, main, MockDio, repository (+1 more)

### Community 101 - "abrir_turno_screen.dart"
Cohesion: 0.21
Nodes (11): abrir_turno_notifier.dart, FormState, abrirTurnoNotifierProvider, AbrirTurnoScreen, _AbrirTurnoScreenState, _baseInicialController, build, _confirmarYAbrir (+3 more)

### Community 102 - "turno_repository_test.dart"
Cohesion: 0.20
Nodes (9): TurnoRepositoryImpl, _arqueoJson, dio, _dioError, _jsonResponse, main, repository, requestOptions (+1 more)

### Community 103 - "../domain/celda.dart"
Cohesion: 0.20
Nodes (10): celda_estado_style.dart, ../../domain/celda.dart, EstadoCelda, build, CeldaEstadoBadge, estado, size, build (+2 more)

### Community 104 - "session_notifier.dart"
Cohesion: 0.21
Nodes (11): ../../../core/network/session_events.dart, ../data/auth_repository_impl.dart, sessionEventsProvider, authRepositoryProvider, build, login, logout, _restore (+3 more)

### Community 105 - "turno_page_dto.dart"
Cohesion: 0.20
Nodes (9): data, fromJson, meta, page, perPage, total, TurnoPageDto, TurnoPageMetaDto (+1 more)

### Community 106 - "turno_repository_impl.dart"
Cohesion: 0.18
Nodes (10): ../domain/turno_repository.dart, dtos/arqueo_turno_dto.dart, dtos/turno_dto.dart, dtos/turno_page_dto.dart, abrir, cerrar, completarArqueo, _dio (+2 more)

### Community 107 - "vehiculo_dto.dart"
Cohesion: 0.17
Nodes (11): ../../domain/vehiculo.dart, createdAt, fromJson, id, placa, propietarioNombre, propietarioTelefono, tipo (+3 more)

### Community 108 - "horario.dart"
Cohesion: 0.15
Nodes (12): int get, apertura, cierre, createdAt, esVigente, hashCode, Horario, id (+4 more)

### Community 109 - "tarifa_list_state.dart"
Cohesion: 0.22
Nodes (8): TarifaListNotifier, copyWith, errorMessage, isLoading, TarifaListState, tarifas, tipoFiltro, _unset

### Community 110 - "nueva_tarifa_screen_test.dart"
Cohesion: 0.22
Nodes (8): package:parqueadero_app/features/tarifas/data/tarifa_repository_impl.dart, package:parqueadero_app/features/tarifas/presentation/nueva_tarifa_screen.dart, authRepository, MockAuthRepository, pumpNuevaTarifaScreen, tarifaCreada, tarifaRepository, usuario

### Community 111 - "usuario_repository.dart"
Cohesion: 0.18
Nodes (10): bool get, actualizar, crear, data, hayMas, listar, page, perPage (+2 more)

### Community 112 - "tarifas_screen_test.dart"
Cohesion: 0.22
Nodes (8): package:parqueadero_app/features/tarifas/presentation/tarifas_screen.dart, authRepository, main, MockAuthRepository, pumpTarifasScreen, tarifa, tarifaRepository, usuario

### Community 113 - "token_storage.dart"
Cohesion: 0.18
Nodes (10): FlutterSecureStorage, _accessTokenKey, clear, readAccessToken, readRefreshToken, _refreshTokenKey, saveTokens, _storage (+2 more)

### Community 114 - "nueva_tarifa_notifier_test.dart"
Cohesion: 0.25
Nodes (7): package:parqueadero_app/features/tarifas/domain/tarifa.dart, package:parqueadero_app/features/tarifas/presentation/nueva_tarifa_notifier.dart, package:parqueadero_app/features/tarifas/presentation/tarifa_list_notifier.dart, container, main, tarifa, tarifaRepository

### Community 115 - "celda_dto.dart"
Cohesion: 0.18
Nodes (10): CeldaDto, codigo, createdAt, estado, fromJson, id, tipoPermitido, toDomain (+2 more)

### Community 116 - "tiempo_transcurrido_text.dart"
Cohesion: 0.20
Nodes (10): build, createState, dispose, horaEntrada, initState, style, TiempoTranscurridoText, _TiempoTranscurridoTextState (+2 more)

### Community 117 - "mensualidad_repository.dart"
Cohesion: 0.18
Nodes (10): cancelar, crear, data, hayMas, listar, MensualidadPageResult, page, perPage (+2 more)

### Community 118 - "loading_skeleton.dart"
Cohesion: 0.15
Nodes (12): Animation, AnimationController, double?, borderRadius, build, _controller, createState, didChangeDependencies (+4 more)

### Community 119 - "salida_notifier.dart"
Cohesion: 0.25
Nodes (7): ../../celdas/presentation/celda_list_notifier.dart, build, confirmarSalida, SalidaNotifier, ticketId, SalidaState, salida_state.dart

### Community 120 - "estado_pago_chip.dart"
Cohesion: 0.33
Nodes (5): estado_pago_style.dart, EstadoPagoMensualidad, build, estado, EstadoPagoChip

### Community 121 - "cobro_preview_notifier.dart"
Cohesion: 0.20
Nodes (9): cobro_preview_state.dart, build, CobroPreviewNotifier, _codigosTerminales, _isRefreshing, ticketId, _timer, CobroPreviewState (+1 more)

### Community 122 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 123 - "usuario_page_dto.dart"
Cohesion: 0.20
Nodes (9): ../../auth/data/dtos/usuario_dto.dart, data, fromJson, meta, page, perPage, total, UsuarioPageDto (+1 more)

### Community 124 - "ticket_abierto_de_celda_notifier.dart"
Cohesion: 0.20
Nodes (8): build, buscar, celdaId, TicketAbiertoDeCeldaNotifier, errorMessage, isLoading, TicketAbiertoDeCeldaState, ticket_abierto_de_celda_state.dart

### Community 125 - "TarifaRepository"
Cohesion: 0.25
Nodes (8): TarifaRepositoryImpl, TarifaRepository, MockTarifaRepository, MockTarifaRepository, MockTarifaRepository, MockTarifaRepository, MockTarifaRepository, MockTarifaRepository

### Community 126 - "ticket_page_dto.dart"
Cohesion: 0.20
Nodes (9): data, fromJson, meta, page, perPage, TicketPageDto, TicketPageMetaDto, total (+1 more)

### Community 127 - "../../../core/theme/app_spacing.dart"
Cohesion: 0.11
Nodes (23): ../../auth/presentation/session_notifier.dart, ../../../core/theme/app_spacing.dart, ../../../core/widgets/acceso_restringido.dart, ../../../core/widgets/detail_skeleton.dart, ../../../core/widgets/empty_state.dart, ../../../core/widgets/error_state.dart, ../../../core/widgets/list_item_skeleton.dart, mensualidadId (+15 more)

### Community 128 - "horario_accion_notifier.dart"
Cohesion: 0.20
Nodes (8): horario_accion_state.dart, actualizar, build, HorarioAccionNotifier, horarioId, errorMessage, HorarioAccionState, isLoading

### Community 129 - "horarios_screen_test.dart"
Cohesion: 0.22
Nodes (8): package:parqueadero_app/features/horarios/presentation/horarios_screen.dart, authRepository, horario, horarioRepository, main, MockAuthRepository, pumpHorariosScreen, usuario

### Community 130 - "Dio"
Cohesion: 0.13
Nodes (14): Dio, dtos/celda_dto.dart, dtos/celda_page_dto.dart, CeldaRepositoryImpl, _dio, listarTodas, marcarMantenimiento, _perPage (+6 more)

### Community 131 - "@JsonSerializable"
Cohesion: 0.10
Nodes (20): @JsonSerializable, accessToken, fromJson, LoginResponseDto, refreshToken, usuario, UsuarioDto, data (+12 more)

### Community 132 - "refresh_interceptor.dart"
Cohesion: 0.15
Nodes (12): Completer, ../../features/auth/data/dtos/refresh_response_dto.dart, Interceptor, AuthInterceptor, _dio, _doRefresh, onError, _refreshAccessToken (+4 more)

### Community 133 - "dart:async"
Cohesion: 0.22
Nodes (9): dart:async, _controller, dispose, emit, events, SessionEvents, SessionEventType, stream (+1 more)

### Community 134 - "tarifa_list_notifier.dart"
Cohesion: 0.18
Nodes (10): ../data/tarifa_repository_impl.dart, ../../domain/tarifa.dart, build, crear, build, _isLoading, setTipoFiltro, nueva_tarifa_state.dart (+2 more)

### Community 135 - "validators.dart"
Cohesion: 0.13
Nodes (14): _emailRegex, emailValidator, formatoError, hasMatch, null, placa, placaConTipoValidator, _placaRegex (+6 more)

### Community 136 - "nuevo_horario_screen_test.dart"
Cohesion: 0.20
Nodes (9): package:parqueadero_app/features/horarios/presentation/nuevo_horario_screen.dart, authRepository, defaultSeleccionarHoraParaTest, fakeSeleccionarHora, horarioCreado, horarioRepository, MockAuthRepository, pumpNuevoHorarioScreen (+1 more)

### Community 137 - "AGENTS.md"
Cohesion: 0.50
Nodes (3): No negociable, Relación con el otro proyecto, Verificación antes de entregar

### Community 138 - "_"
Cohesion: 0.29
Nodes (8): _, AppColors, asfalto, concreto, demarcacion, linea, tinta, verdeSenal

### Community 139 - "_"
Cohesion: 0.29
Nodes (8): _, AppSpacing, gutter, lg, md, sm, xl, xs

### Community 140 - "ticket_repository_test.dart"
Cohesion: 0.18
Nodes (10): TicketRepositoryImpl, _celdaJson, dio, _dioError, _jsonResponse, main, repository, requestOptions (+2 more)

### Community 141 - "mensualidad_repository_test.dart"
Cohesion: 0.10
Nodes (20): Exception, ApiException, AppException, NetworkException, MockDio, dio, _dioError, _jsonResponse (+12 more)

### Community 142 - "_"
Cohesion: 0.33
Nodes (7): _, AppMotion, curve, effective, fast, medium, slow

### Community 143 - "mensualidad_repository_impl.dart"
Cohesion: 0.22
Nodes (8): ../../../core/network/api_client.dart, ../domain/mensualidad_repository.dart, dtos/mensualidad_dto.dart, dtos/mensualidad_page_dto.dart, cancelar, crear, _dio, listar

### Community 144 - "recibo_view.dart"
Cohesion: 0.20
Nodes (9): desglose_view.dart, ../../domain/recibo.dart, Recibo, build, kReciboAnchoMm80, _pieStyle, recibo, ReciboView (+1 more)

### Community 145 - "app_page_transitions.dart"
Cohesion: 0.33
Nodes (5): app_motion.dart, AppPageTransitionsBuilder, Offset, PageTransitionsBuilder, T

### Community 146 - "tarifaListNotifierProvider"
Cohesion: 0.17
Nodes (11): NuevaTarifaNotifier, errorMessage, isLoading, NuevaTarifaState, tarifaListNotifierProvider, build, TarifasScreen, build (+3 more)

### Community 148 - "State"
Cohesion: 0.28
Nodes (9): LoadingSkeleton, _LoadingSkeletonState, _EditarHorarioDialog, _EditarHorarioDialogState, _TipoVehiculoDropdown, _TipoVehiculoDropdownState, SingleTickerProviderStateMixin, State (+1 more)

### Community 149 - "usuario_repository_test.dart"
Cohesion: 0.11
Nodes (16): ../domain/usuario_repository.dart, dtos/usuario_page_dto.dart, actualizar, crear, _dio, listar, UsuarioRepositoryImpl, usuarioRepositoryProvider (+8 more)

### Community 150 - "_"
Cohesion: 0.40
Nodes (6): _, AppBreakpoints, contentMaxWidth, gridMaxWidth, mobile, tablet

### Community 151 - "_"
Cohesion: 0.50
Nodes (5): _, AppElevation, flat, low, raised

### Community 152 - "horario_repository_impl.dart"
Cohesion: 0.20
Nodes (9): ../domain/horario_repository.dart, dtos/horario_dto.dart, dtos/horario_page_dto.dart, actualizar, cerrar, crear, _dio, listarTodas (+1 more)

### Community 153 - "HorarioRepository"
Cohesion: 0.29
Nodes (7): HorarioRepositoryImpl, HorarioRepository, MockHorarioRepository, MockHorarioRepository, MockHorarioRepository, MockHorarioRepository, MockHorarioRepository

### Community 154 - "seleccionar_hora.dart"
Cohesion: 0.33
Nodes (5): formatHora, SeleccionarHora, seleccionarHoraPorDefecto, showTimePicker, typedef

### Community 155 - "tarifa_repository.dart"
Cohesion: 0.29
Nodes (6): actualizar, cerrar, crear, listarTodas, simular, tarifa.dart

### Community 156 - "home_screen.dart"
Cohesion: 0.33
Nodes (5): ../domain/usuario.dart, build, HomeScreen, widgets/admin_home_dashboard.dart, widgets/operador_home_dashboard.dart

### Community 157 - "_"
Cohesion: 0.50
Nodes (5): _, AppRadius, lg, md, sm

### Community 158 - "animated_count_text.dart"
Cohesion: 0.29
Nodes (6): AnimatedCountText, build, style, value, TextStyle?, ../theme/app_motion.dart

### Community 159 - "tarifa_list_notifier_test.dart"
Cohesion: 0.29
Nodes (6): MockTarifaRepository, container, main, mantenerVivo, tarifa, tarifaRepository

### Community 160 - "tarifa_accion_notifier_test.dart"
Cohesion: 0.29
Nodes (6): package:parqueadero_app/features/tarifas/domain/tarifa_repository.dart, package:parqueadero_app/features/tarifas/presentation/tarifa_accion_notifier.dart, container, main, tarifa, tarifaRepository

### Community 161 - "_"
Cohesion: 0.33
Nodes (7): _, authenticated, checking, SessionStatus, status, unauthenticated, usuario

### Community 162 - "elapsed_time.dart"
Cohesion: 0.50
Nodes (3): formatElapsed, horas, minutos

### Community 163 - "nuevo_horario_notifier.dart"
Cohesion: 0.18
Nodes (9): ../domain/horario.dart, horario_list_notifier.dart, copyWith, errorMessage, horarios, isLoading, build, crear (+1 more)

### Community 164 - "../../domain/mensualidad.dart"
Cohesion: 0.06
Nodes (42): Color, ../../../../core/theme/status_style.dart, ../../domain/mensualidad.dart, IconData, _, color, icon, of (+34 more)

### Community 165 - "horario_repository.dart"
Cohesion: 0.33
Nodes (5): horario.dart, actualizar, cerrar, crear, listarTodas

### Community 166 - "celda_leyenda.dart"
Cohesion: 0.12
Nodes (16): CustomPainter, _LineasDemarcacionPainter, _HatchPainter, build, CeldaLeyenda, _grosor, label, _lado (+8 more)

### Community 169 - "material_hero.dart"
Cohesion: 0.33
Nodes (5): build, child, MaterialHero, tag, Widget

### Community 172 - "static const"
Cohesion: 0.67
Nodes (4): _, AppTypography, montoDestacado, static const

### Community 173 - "build"
Cohesion: 0.33
Nodes (6): horarioAccionNotifierProvider, build, _confirmarCerrar, _VigenteCard, Route /horarios/nuevo, main

### Community 174 - "turno_detail_notifier.dart"
Cohesion: 0.29
Nodes (6): build, cargar, TurnoDetailNotifier, turnoId, TurnoDetailState, turno_detail_state.dart

### Community 175 - "tarifa_accion_notifier.dart"
Cohesion: 0.17
Nodes (11): tarifaRepositoryProvider, actualizar, build, cerrar, TarifaAccionNotifier, tarifaId, errorMessage, isLoading (+3 more)

### Community 176 - "turno_estado_chip.dart"
Cohesion: 0.33
Nodes (5): EstadoTurno, build, estado, TurnoEstadoChip, turno_estado_style.dart

### Community 177 - "TipoVehiculo"
Cohesion: 0.33
Nodes (5): carro,
  moto,
  bicicleta,, fromBackend, otro, TipoVehiculo, toBackend

### Community 178 - "_"
Cohesion: 0.50
Nodes (5): _, apiBaseUrl, AppConfig, appConfigProvider, fromEnvironment

### Community 179 - "Notifier"
Cohesion: 0.18
Nodes (10): CeldaGridYaVioDatosNotifier, NuevaMensualidadNotifier, errorMessage, isLoading, NuevaMensualidadState, RegistrarEntradaNotifier, RegistrarEntradaState, TicketListNotifier (+2 more)

### Community 180 - "ticket_estado_chip.dart"
Cohesion: 0.33
Nodes (5): EstadoTicket, build, estado, TicketEstadoChip, ticket_estado_style.dart

### Community 181 - "AbrirTurnoNotifier"
Cohesion: 0.40
Nodes (4): AbrirTurnoNotifier, AbrirTurnoState, errorMessage, isLoading

## Knowledge Gaps
- **1754 isolated node(s):** `AppConfig`, `apiBaseUrl`, `appConfigProvider`, `fromEnvironment`, `otro` (+1749 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2064 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `TipoVehiculo` connect `TipoVehiculo` to `nueva_mensualidad_screen.dart`, `registrar_entrada_screen.dart`, `tarifa_grupo_card.dart`, `tarifa.dart`, `tarifa_list_state.dart`, `celda_list_state.dart`, `celda.dart`, `nueva_tarifa_screen.dart`, `recibo.dart`, `../../../core/domain/tipo_vehiculo.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Why does `_` connect `_` to `package:flutter/material.dart`, `static const`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `AuthRepository` connect `Mock` to `operador_home_dashboard_test.dart`, `horarios_screen_test.dart`, `login_screen_test.dart`, `turno_cierre_screen_test.dart`, `package:parqueadero_app/features/auth/domain/usuario.dart`, `nueva_mensualidad_screen_test.dart`, `celdas_screen_test.dart`, `package:flutter_test/flutter_test.dart`, `nuevo_horario_screen_test.dart`, `nueva_tarifa_screen_test.dart`, `celda_card_test.dart`, `auth_repository.dart`, `tarifas_screen_test.dart`, `celda_detail_screen_test.dart`, `package:dio/dio.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **What connects `AppConfig`, `apiBaseUrl`, `appConfigProvider` to the rest of the system?**
  _1754 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `operador_home_dashboard_test.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02582398912674142 - nodes in this community are weakly interconnected._
- **Should `package:flutter_riverpod/flutter_riverpod.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05585106382978723 - nodes in this community are weakly interconnected._
- **Should `turno_kpis_view.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.08333333333333333 - nodes in this community are weakly interconnected._