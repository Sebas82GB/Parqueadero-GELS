# Graph Report - parqueadero_app  (2026-09-15)

## Corpus Check
- 325 files · ~100,922 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3122 nodes · 5535 edges · 164 communities (159 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `90ca6586`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- MockAuthRepository
- usuario_detail_screen.dart
- turno_kpis_view.dart
- mensualidad_repository_impl.dart
- app_router.dart
- sessionNotifierProvider
- turno_activo_indicator.dart
- package:parqueadero_app/features/auth/data/auth_repository_impl.dart
- nuevo_horario_screen.dart
- cobro_preview_notifier.dart
- tarifa_grupo_card.dart
- horarios_screen.dart
- api_exception.dart
- Mock
- login_screen_test.dart
- package:mocktail/mocktail.dart
- package:flutter_test/flutter_test.dart
- recibo_dto.dart
- celda_card.dart
- ticket.dart
- ticket_dto.dart
- celda_list_state.dart
- ../../../../core/utils/money.dart
- ticket_list_state.dart
- StatelessWidget
- dashboard_metric_card.dart
- cobro_preview_state.dart
- horario_page_dto.dart
- nueva_tarifa_screen.dart
- recibo.dart
- package:parqueadero_app/core/network/api_exception.dart
- usuario_list_notifier.dart
- turno_filtros_bar.dart
- turno_page_dto.dart
- ticket_repository_impl.dart
- package:flutter/material.dart
- operador_home_dashboard.dart
- package:json_annotation/json_annotation.dart
- nueva_mensualidad_screen.dart
- registrar_entrada_screen.dart
- pago.dart
- login_controller.dart
- celda_accion_rapida_sheet.dart
- _
- usuario_repository_impl.dart
- tarifa.dart
- tarifa_repository_impl.dart
- mensualidad.dart
- ticket_list_notifier.dart
- arqueo_turno_dto.dart
- ticket_detail_notifier.dart
- registrar_salida_screen_test.dart
- int?
- tarifa_list_notifier.dart
- buscar_placa_screen.dart
- auth_repository_impl.dart
- mensualidad_page_dto.dart
- ../../../core/domain/tipo_vehiculo.dart
- registrar_entrada_screen_test.dart
- desglose_item.dart
- arqueo_turno.dart
- turno.dart
- vehiculo.dart
- mensualidad_accion_notifier.dart
- celdas_screen.dart
- turno_cierre_screen.dart
- turno_cierre_notifier.dart
- horario_accion_notifier.dart
- celda_list_notifier.dart
- login_screen.dart
- refresh_interceptor_test.dart
- ../../domain/ticket.dart
- nueva_mensualidad_notifier_test.dart
- turno_dto.dart
- ticket_repository_test.dart
- horario_dto.dart
- ticket_repository.dart
- nuevo_horario_screen_test.dart
- DateTime
- nuevo_usuario_screen.dart
- tarifa_repository_test.dart
- turno_repository.dart
- celda_accion_notifier.dart
- celda_card_test.dart
- vigencia_chip.dart
- celda.dart
- String?
- mensualidad_list_state.dart
- tarifa_dto.dart
- pago_dto.dart
- registrar_salida_screen.dart
- turno_list_notifier.dart
- turno_list_state.dart
- Notifier
- Sistema de diseño — App de Parqueadero
- auth_repository.dart
- turno_activo_notifier.dart
- mensualidad_list_notifier.dart
- turno_cierre_state.dart
- operador_home_dashboard_test.dart
- horario_repository_test.dart
- abrir_turno_screen.dart
- usuario.dart
- ../domain/celda.dart
- session_notifier.dart
- upper_case_text_formatter.dart
- turno_repository_impl.dart
- vehiculo_dto.dart
- horario.dart
- usuario_list_state.dart
- turnoRepositoryProvider
- usuario_repository.dart
- status_style_test.dart
- token_storage.dart
- arqueo_summary_view.dart
- celda_dto.dart
- celda_repository_impl.dart
- mensualidad_repository.dart
- loading_skeleton.dart
- ../../../core/network/api_exception.dart
- estado_pago_chip.dart
- turno_detail_notifier.dart
- manifest.json
- List
- ticket_abierto_de_celda_notifier.dart
- _
- @JsonSerializable
- package:flutter_riverpod/flutter_riverpod.dart
- Dio
- tarifa_page_dto.dart
- package:dio/dio.dart
- session_events.dart
- mensualidad_filtros_bar.dart
- validators.dart
- AGENTS.md
- _
- _
- celda_detail_screen_test.dart
- mensualidad_repository_test.dart
- _
- recibo_view.dart
- app_page_transitions.dart
- ../../../../core/utils/tipo_vehiculo_label.dart
- parqueadero_app
- build
- _
- static const
- horario_repository_impl.dart
- seleccionar_hora.dart
- _
- _
- tarifa_list_state.dart
- _
- elapsed_time.dart
- print_launcher_web.dart
- rol_usuario_label.dart
- print_launcher.dart
- print_launcher_stub.dart
- turno_repository_test.dart
- NuevaTarifaNotifier
- tarifa_accion_notifier.dart
- TarifaAccionNotifier
- ../../domain/mensualidad.dart
- abrir_turno_state.dart

## God Nodes (most connected - your core abstractions)
1. `sessionNotifierProvider` - 48 edges
2. `AuthRepository` - 34 edges
3. `TicketRepository` - 27 edges
4. `celdaListNotifierProvider` - 24 edges
5. `_` - 23 edges
6. `TurnoRepository` - 18 edges
7. `CeldaRepository` - 17 edges
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

## Communities (164 total, 5 thin omitted)

### Community 0 - "MockAuthRepository"
Cohesion: 0.03
Nodes (86): MockAuthRepository, MockTurnoRepository, package:parqueadero_app/core/network/session_events.dart, package:parqueadero_app/core/widgets/detail_skeleton.dart, package:parqueadero_app/features/auth/domain/auth_repository.dart, package:parqueadero_app/features/auth/presentation/session_notifier.dart, package:parqueadero_app/features/auth/presentation/session_state.dart, package:parqueadero_app/features/turnos/data/turno_repository_impl.dart (+78 more)

### Community 1 - "usuario_detail_screen.dart"
Cohesion: 0.06
Nodes (40): ../../../../core/utils/rol_usuario_label.dart, ../../../../core/widgets/filtros_bar.dart, ../data/usuario_repository_impl.dart, build, crear, NuevoUsuarioNotifier, NuevoUsuarioState, build (+32 more)

### Community 2 - "turno_kpis_view.dart"
Cohesion: 0.07
Nodes (26): Duration, build, child, MaterialHero, tag, ahora, arqueo, build (+18 more)

### Community 3 - "mensualidad_repository_impl.dart"
Cohesion: 0.22
Nodes (8): ../../../core/network/api_client.dart, ../domain/mensualidad_repository.dart, dtos/mensualidad_dto.dart, dtos/mensualidad_page_dto.dart, cancelar, crear, _dio, listar

### Community 4 - "app_router.dart"
Cohesion: 0.05
Nodes (42): ChangeNotifier, core/config/app_config.dart, core/router/app_router.dart, core/theme/app_theme.dart, ../../features/auth/presentation/home_screen.dart, ../../features/auth/presentation/login_screen.dart, ../../features/auth/presentation/session_notifier.dart, ../../features/auth/presentation/session_state.dart (+34 more)

### Community 5 - "sessionNotifierProvider"
Cohesion: 0.08
Nodes (42): ConsumerWidget, ../domain/usuario.dart, build, HomeScreen, sessionNotifierProvider, AdminHomeDashboard, build, build (+34 more)

### Community 6 - "turno_activo_indicator.dart"
Cohesion: 0.17
Nodes (12): actionLabel, _Banner, createState, _dialogoMostrado, onAction, onVerArqueo, _preguntandoInicio, style (+4 more)

### Community 7 - "package:parqueadero_app/features/auth/data/auth_repository_impl.dart"
Cohesion: 0.03
Nodes (64): Hero, package:intl/date_symbol_data_local.dart, package:parqueadero_app/core/utils/money.dart, package:parqueadero_app/core/widgets/acceso_restringido.dart, package:parqueadero_app/core/widgets/empty_state.dart, package:parqueadero_app/core/widgets/error_state.dart, package:parqueadero_app/features/auth/data/auth_repository_impl.dart, package:parqueadero_app/features/horarios/presentation/horarios_screen.dart (+56 more)

### Community 8 - "nuevo_horario_screen.dart"
Cohesion: 0.10
Nodes (20): nuevoHorarioNotifierProvider, _apertura, build, _cierre, createState, _elegirApertura, _elegirCierre, enabled (+12 more)

### Community 9 - "cobro_preview_notifier.dart"
Cohesion: 0.17
Nodes (10): cobro_preview_state.dart, build, RelojNotifier, _timer, build, _codigosTerminales, _isRefreshing, ticketId (+2 more)

### Community 10 - "tarifa_grupo_card.dart"
Cohesion: 0.11
Nodes (20): tarifaAccionNotifierProvider, build, _confirmarCerrar, createState, dispose, _editar, _EditarTarifaDialog, _EditarTarifaDialogState (+12 more)

### Community 11 - "horarios_screen.dart"
Cohesion: 0.09
Nodes (24): horario_accion_notifier.dart, horarioAccionNotifierProvider, _apertura, build, _cierre, _confirmarCerrar, createState, _editar (+16 more)

### Community 12 - "api_exception.dart"
Cohesion: 0.12
Nodes (17): DioExceptionType, Exception, ApiErrorDetail, ApiException, AppException, code, details, field (+9 more)

### Community 13 - "Mock"
Cohesion: 0.04
Nodes (75): celda.dart, AuthRepository, CeldaRepository, listarTodas, marcarMantenimiento, volverALibre, MensualidadRepositoryImpl, MensualidadRepository (+67 more)

### Community 14 - "login_screen_test.dart"
Cohesion: 0.11
Nodes (17): ElevatedButton, package:parqueadero_app/core/theme/app_breakpoints.dart, package:parqueadero_app/features/auth/presentation/login_screen.dart, authRepository, canal, claro, _contraste, fillAndSubmit (+9 more)

### Community 15 - "package:mocktail/mocktail.dart"
Cohesion: 0.04
Nodes (69): MockCeldaRepository, package:mocktail/mocktail.dart, package:parqueadero_app/features/auth/presentation/widgets/admin_home_dashboard.dart, package:parqueadero_app/features/celdas/data/celda_repository_impl.dart, package:parqueadero_app/features/celdas/domain/celda.dart, package:parqueadero_app/features/celdas/domain/celda_repository.dart, package:parqueadero_app/features/celdas/presentation/celda_accion_notifier.dart, package:parqueadero_app/features/celdas/presentation/celda_list_notifier.dart (+61 more)

### Community 16 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.08
Nodes (22): dart:async, NavigatorState, package:flutter_test/flutter_test.dart, package:parqueadero_app/core/theme/app_theme.dart, package:parqueadero_app/core/utils/elapsed_time.dart, package:parqueadero_app/core/utils/validators.dart, package:parqueadero_app/core/widgets/animated_count_text.dart, package:parqueadero_app/features/celdas/presentation/celdas_screen.dart (+14 more)

### Community 17 - "recibo_dto.dart"
Cohesion: 0.06
Nodes (29): ../../domain/desglose_item.dart, desgloseFromJson, map, celda, ciudad, consecutivo, desglose, direccion (+21 more)

### Community 18 - "celda_card.dart"
Cohesion: 0.05
Nodes (37): celda_accion_rapida_sheet.dart, celda_quick_actions_sheet.dart, ../../../../core/theme/app_elevation.dart, ../../../../core/theme/app_radius.dart, ../../../../core/utils/haptics.dart, ../../../core/widgets/loading_skeleton.dart, CustomPainter, _LineasDemarcacionPainter (+29 more)

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

### Community 22 - "../../../../core/utils/money.dart"
Cohesion: 0.09
Nodes (22): ../../../../core/theme/app_typography.dart, ../../../../core/utils/bogota_time.dart, ../../../../core/utils/money.dart, ../../../../core/widgets/material_hero.dart, estado_pago_chip.dart, Mensualidad, build, mensualidad (+14 more)

### Community 23 - "ticket_list_state.dart"
Cohesion: 0.10
Nodes (18): EstadoTicket, copyWith, desdeFiltro, errorMessage, estadoFiltro, hastaFiltro, hayMas, isLoading (+10 more)

### Community 24 - "StatelessWidget"
Cohesion: 0.10
Nodes (21): ../../../../core/theme/app_motion.dart, ../../../../core/widgets/animated_count_text.dart, _EstadoCentrado, _HandleBar, _SheetSkeleton, _TarjetaMonto, ancho, _BarraOcupacion (+13 more)

### Community 25 - "dashboard_metric_card.dart"
Cohesion: 0.08
Nodes (24): animated_count_text.dart, build, DashboardActionGroup, DashboardActionItem, _DashboardActionRow, icon, item, items (+16 more)

### Community 26 - "cobro_preview_state.dart"
Cohesion: 0.15
Nodes (11): desglose_item_dto.dart, ../domain/cobro_preview.dart, cobroPreviewFromJson, CobroPreview, CobroPreviewNotifier, CobroPreviewState, copyWith, error (+3 more)

### Community 27 - "horario_page_dto.dart"
Cohesion: 0.20
Nodes (9): horario_dto.dart, data, fromJson, HorarioPageDto, HorarioPageMetaDto, meta, page, perPage (+1 more)

### Community 28 - "nueva_tarifa_screen.dart"
Cohesion: 0.08
Nodes (27): nuevaTarifaNotifierProvider, build, createState, _debounce, dispose, _duracionesPreset, duracionLabel, _duracionMinutos (+19 more)

### Community 29 - "recibo.dart"
Cohesion: 0.08
Nodes (24): celda, ciudad, consecutivo, desglose, direccion, Establecimiento, fechaEmision, horaEntrada (+16 more)

### Community 30 - "package:parqueadero_app/core/network/api_exception.dart"
Cohesion: 0.03
Nodes (78): UsuarioRepository, MockUsuarioRepository, package:parqueadero_app/core/network/api_exception.dart, package:parqueadero_app/features/auth/domain/usuario.dart, package:parqueadero_app/features/turnos/presentation/turnos_historial_screen.dart, package:parqueadero_app/features/turnos/presentation/widgets/turno_list_item.dart, package:parqueadero_app/features/usuarios/data/usuario_repository_impl.dart, package:parqueadero_app/features/usuarios/domain/usuario_repository.dart (+70 more)

### Community 31 - "usuario_list_notifier.dart"
Cohesion: 0.13
Nodes (14): agregarUsuario, build, cargar, cargarMas, _isLoading, limpiarFiltros, _perPage, reemplazarUsuario (+6 more)

### Community 32 - "turno_filtros_bar.dart"
Cohesion: 0.07
Nodes (32): ConsumerState, ConsumerStatefulWidget, formatBogota, toBogota, formatMoney, ticketListNotifierProvider, build, TicketsHistorialScreen (+24 more)

### Community 33 - "turno_page_dto.dart"
Cohesion: 0.20
Nodes (9): data, fromJson, meta, page, perPage, total, TurnoPageDto, TurnoPageMetaDto (+1 more)

### Community 34 - "ticket_repository_impl.dart"
Cohesion: 0.13
Nodes (13): ../../domain/pago.dart, ../domain/ticket_repository.dart, dtos/cobro_preview_dto.dart, dtos/ticket_dto.dart, dtos/ticket_page_dto.dart, _dio, listar, obtenerPorId (+5 more)

### Community 35 - "package:flutter/material.dart"
Cohesion: 0.06
Nodes (32): empty_state.dart, AccesoRestringido, build, build, DetailSkeleton, lineas, actionLabel, build (+24 more)

### Community 36 - "operador_home_dashboard.dart"
Cohesion: 0.11
Nodes (17): ../../../../core/theme/app_breakpoints.dart, ../../../../core/theme/app_colors.dart, ../../../../core/widgets/dashboard_action_group.dart, ../../../../core/widgets/dashboard_metric_card.dart, _CerrarSesionRow, onTap, _AccionPrincipal, _AccionSecundaria (+9 more)

### Community 37 - "package:json_annotation/json_annotation.dart"
Cohesion: 0.12
Nodes (14): celda_dto.dart, accessToken, fromJson, RefreshResponseDto, refreshToken, CeldaPageDto, CeldaPageMetaDto, data (+6 more)

### Community 38 - "nueva_mensualidad_screen.dart"
Cohesion: 0.11
Nodes (19): ../../celdas/domain/celda.dart, DateTimeRange?, nuevaMensualidadNotifierProvider, build, _celda, createState, dispose, _elegirRango (+11 more)

### Community 39 - "registrar_entrada_screen.dart"
Cohesion: 0.10
Nodes (21): ../../celdas/presentation/widgets/celda_estado_badge.dart, ../../../core/utils/placa_tipo.dart, celdaId, _codigosCeldaEspecifica, createState, dispose, enabled, _enviando (+13 more)

### Community 40 - "pago.dart"
Cohesion: 0.09
Nodes (21): efectivo,
  tarjeta,, anulado, createdAt, estado, EstadoPago, fecha, fromBackend, hashCode (+13 more)

### Community 41 - "login_controller.dart"
Cohesion: 0.29
Nodes (7): build, error, isLoading, LoginController, LoginState, submit, ../session_notifier.dart

### Community 42 - "celda_accion_rapida_sheet.dart"
Cohesion: 0.09
Nodes (22): class, _buscando, _buscar, celdaId, child, createState, dispose, esAncho (+14 more)

### Community 43 - "_"
Cohesion: 0.10
Nodes (21): app_colors.dart, app_elevation.dart, app_page_transitions.dart, app_radius.dart, app_spacing.dart, _, AppTheme, _colorScheme (+13 more)

### Community 44 - "usuario_repository_impl.dart"
Cohesion: 0.22
Nodes (8): ../domain/usuario_repository.dart, dtos/usuario_page_dto.dart, actualizar, crear, _dio, listar, UsuarioRepositoryImpl, usuarioRepositoryProvider

### Community 45 - "tarifa.dart"
Cohesion: 0.13
Nodes (14): createdAt, esVigente, hashCode, id, operator, Tarifa, tipoVehiculo, updatedAt (+6 more)

### Community 46 - "tarifa_repository_impl.dart"
Cohesion: 0.18
Nodes (10): ../domain/tarifa_repository.dart, dtos/tarifa_dto.dart, dtos/tarifa_page_dto.dart, actualizar, cerrar, crear, _dio, listarTodas (+2 more)

### Community 47 - "mensualidad.dart"
Cohesion: 0.10
Nodes (19): cancelada, celdaId, createdAt, diasPorVencerDefault, estadoPago, fechaFin, fechaInicio, fechaPago (+11 more)

### Community 48 - "ticket_list_notifier.dart"
Cohesion: 0.17
Nodes (11): build, cargar, cargarMas, _isLoading, limpiarFiltros, _perPage, refrescar, setEstadoFiltro (+3 more)

### Community 49 - "arqueo_turno_dto.dart"
Cohesion: 0.10
Nodes (19): apertura, baseInicial, cierre, diferencia, efectivo, efectivoContado, efectivoEsperado, estado (+11 more)

### Community 50 - "ticket_detail_notifier.dart"
Cohesion: 0.20
Nodes (10): ticketRepositoryProvider, buscar, refrescar, build, cargar, copyWith, TicketDetailNotifier, ticketId (+2 more)

### Community 51 - "registrar_salida_screen_test.dart"
Cohesion: 0.03
Nodes (62): ConstrainedBox, package:parqueadero_app/core/domain/tipo_vehiculo.dart, package:parqueadero_app/core/theme/app_typography.dart, package:parqueadero_app/core/utils/placa_tipo.dart, package:parqueadero_app/core/widgets/error_banner.dart, package:parqueadero_app/features/tickets/data/dtos/desglose_item_dto.dart, package:parqueadero_app/features/tickets/data/dtos/recibo_dto.dart, package:parqueadero_app/features/tickets/domain/desglose_item.dart (+54 more)

### Community 52 - "int?"
Cohesion: 0.12
Nodes (15): int?, activo, baseInicialTurno, createdAt, email, fromJson, id, nombre (+7 more)

### Community 53 - "tarifa_list_notifier.dart"
Cohesion: 0.22
Nodes (9): tarifaRepositoryProvider, cerrar, build, _isLoading, refrescar, setTipoFiltro, TarifaListNotifier, TarifaListState (+1 more)

### Community 54 - "buscar_placa_screen.dart"
Cohesion: 0.13
Nodes (17): buscar_placa_notifier.dart, ../../../../core/utils/elapsed_time.dart, ../../../core/utils/upper_case_text_formatter.dart, buscarPlacaNotifierProvider, build, _buscar, BuscarPlacaScreen, _BuscarPlacaScreenState (+9 more)

### Community 55 - "auth_repository_impl.dart"
Cohesion: 0.14
Nodes (13): ../domain/auth_repository.dart, dtos/login_response_dto.dart, dtos/usuario_dto.dart, AuthRepositoryImpl, _dio, login, logout, restoreSession (+5 more)

### Community 56 - "mensualidad_page_dto.dart"
Cohesion: 0.20
Nodes (9): data, fromJson, MensualidadPageDto, MensualidadPageMetaDto, meta, page, perPage, total (+1 more)

### Community 57 - "../../../core/domain/tipo_vehiculo.dart"
Cohesion: 0.33
Nodes (5): ../../../core/domain/tipo_vehiculo.dart, build, limpiar, simular, tarifa_simulacion_state.dart

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

### Community 62 - "vehiculo.dart"
Cohesion: 0.12
Nodes (15): carro,
  moto,
  bicicleta,, fromBackend, otro, TipoVehiculo, toBackend, createdAt, hashCode, id (+7 more)

### Community 63 - "mensualidad_accion_notifier.dart"
Cohesion: 0.17
Nodes (11): ../data/mensualidad_repository_impl.dart, mensualidadRepositoryProvider, build, cancelar, MensualidadAccionNotifier, mensualidadId, errorMessage, isLoading (+3 more)

### Community 64 - "celdas_screen.dart"
Cohesion: 0.12
Nodes (19): build, celdaGridYaVioDatosProvider, CeldasScreen, _CeldasScreenState, count, createState, dispose, _entradaController (+11 more)

### Community 65 - "turno_cierre_screen.dart"
Cohesion: 0.13
Nodes (16): ../../../core/utils/validators.dart, ../../../core/widgets/error_banner.dart, turnoCierreNotifierProvider, build, _completandoArqueo, _confirmarYCerrar, _contadoController, _contadoValidator (+8 more)

### Community 66 - "turno_cierre_notifier.dart"
Cohesion: 0.22
Nodes (8): abrir_turno_state.dart, ../../data/turno_repository_impl.dart, build, build, completarArqueo, turnoId, ../turno_activo_notifier.dart, turno_cierre_state.dart

### Community 67 - "horario_accion_notifier.dart"
Cohesion: 0.07
Nodes (31): ../data/horario_repository_impl.dart, ../domain/horario.dart, horario_accion_state.dart, horario_list_notifier.dart, horario_list_state.dart, horarioRepositoryProvider, actualizar, build (+23 more)

### Community 68 - "celda_list_notifier.dart"
Cohesion: 0.12
Nodes (15): celda_list_state.dart, build, _cargarTicketInfoPorCeldaId, CeldaListNotifier, _isRefreshing, limpiarFiltros, _pollTimer, reemplazarCelda (+7 more)

### Community 69 - "login_screen.dart"
Cohesion: 0.08
Nodes (27): GlobalKey, loginControllerProvider, _alturaMarcaCompacta, build, createState, _demarcacionBorder, dispose, _emailController (+19 more)

### Community 70 - "refresh_interceptor_test.dart"
Cohesion: 0.13
Nodes (14): dart:convert, DioException, HttpClientAdapter, MockTokenStorage, package:parqueadero_app/core/network/refresh_interceptor.dart, package:parqueadero_app/features/auth/data/token_storage.dart, adapter, dio (+6 more)

### Community 71 - "../../domain/ticket.dart"
Cohesion: 0.14
Nodes (13): ../../domain/ticket.dart, Ticket, buscado, errorMessage, isLoading, ticket, error, SalidaStep (+5 more)

### Community 72 - "nueva_mensualidad_notifier_test.dart"
Cohesion: 0.10
Nodes (22): MockMensualidadRepository, package:parqueadero_app/features/mensualidades/data/mensualidad_repository_impl.dart, package:parqueadero_app/features/mensualidades/domain/mensualidad.dart, package:parqueadero_app/features/mensualidades/domain/mensualidad_repository.dart, package:parqueadero_app/features/mensualidades/presentation/mensualidad_accion_notifier.dart, package:parqueadero_app/features/mensualidades/presentation/mensualidad_list_notifier.dart, package:parqueadero_app/features/mensualidades/presentation/nueva_mensualidad_notifier.dart, container (+14 more)

### Community 73 - "turno_dto.dart"
Cohesion: 0.11
Nodes (17): apertura, baseInicial, cierre, createdAt, diferencia, efectivoContado, efectivoEsperado, estado (+9 more)

### Community 74 - "ticket_repository_test.dart"
Cohesion: 0.20
Nodes (9): _celdaJson, dio, _dioError, _jsonResponse, main, repository, requestOptions, _ticketJson (+1 more)

### Community 75 - "horario_dto.dart"
Cohesion: 0.18
Nodes (10): apertura, cierre, createdAt, fromJson, HorarioDto, id, toDomain, updatedAt (+2 more)

### Community 76 - "ticket_repository.dart"
Cohesion: 0.13
Nodes (14): cobro_preview.dart, data, hayMas, listar, obtenerPorId, page, perPage, previsualizarCobro (+6 more)

### Community 77 - "nuevo_horario_screen_test.dart"
Cohesion: 0.05
Nodes (46): horario.dart, _, apiBaseUrl, AppConfig, appConfigProvider, fromEnvironment, HorarioRepositoryImpl, actualizar (+38 more)

### Community 78 - "DateTime"
Cohesion: 0.29
Nodes (6): DateTime, desglose_item.dart, desglose, horaEntrada, horaSalida, valorTotal

### Community 79 - "nuevo_usuario_screen.dart"
Cohesion: 0.16
Nodes (13): nuevoUsuarioNotifierProvider, build, createState, dispose, _emailController, _formKey, _nombreController, NuevoUsuarioScreen (+5 more)

### Community 80 - "tarifa_repository_test.dart"
Cohesion: 0.06
Nodes (37): TarifaRepositoryImpl, actualizar, cerrar, crear, listarTodas, simular, TarifaRepository, MockTarifaRepository (+29 more)

### Community 81 - "turno_repository.dart"
Cohesion: 0.14
Nodes (13): arqueo_turno.dart, abrir, cerrar, completarArqueo, data, hayMas, listar, obtenerArqueo (+5 more)

### Community 82 - "celda_accion_notifier.dart"
Cohesion: 0.17
Nodes (12): celda_accion_state.dart, ../celda_list_notifier.dart, ../data/celda_repository_impl.dart, celdaRepositoryProvider, build, CeldaAccionNotifier, celdaId, _ejecutar (+4 more)

### Community 83 - "celda_card_test.dart"
Cohesion: 0.06
Nodes (30): BoxDecoration, Container, Icon, package:parqueadero_app/core/theme/app_colors.dart, package:parqueadero_app/features/celdas/presentation/widgets/celda_accion_rapida_sheet.dart, package:parqueadero_app/features/celdas/presentation/widgets/celda_card.dart, package:parqueadero_app/features/celdas/presentation/widgets/zona_header.dart, package:parqueadero_app/features/turnos/presentation/widgets/turno_activo_indicator.dart (+22 more)

### Community 84 - "vigencia_chip.dart"
Cohesion: 0.33
Nodes (5): VigenciaMensualidad, build, vigencia, VigenciaChip, vigencia_style.dart

### Community 85 - "celda.dart"
Cohesion: 0.14
Nodes (13): Celda, codigo, createdAt, estado, fromBackend, hashCode, id, mantenimiento (+5 more)

### Community 86 - "String?"
Cohesion: 0.08
Nodes (20): errorMessage, isLoading, celdaId, createdAt, estadoPago, fechaFin, fechaInicio, fechaPago (+12 more)

### Community 87 - "mensualidad_list_state.dart"
Cohesion: 0.15
Nodes (12): copyWith, errorMessage, estadoPagoFiltro, hayMas, isLoading, isLoadingMore, mensualidades, page (+4 more)

### Community 88 - "tarifa_dto.dart"
Cohesion: 0.14
Nodes (13): createdAt, fromJson, id, TarifaDto, tipoVehiculo, toDomain, updatedAt, valorMes (+5 more)

### Community 89 - "pago_dto.dart"
Cohesion: 0.14
Nodes (13): createdAt, estado, fecha, fromJson, id, mensualidadId, metodo, monto (+5 more)

### Community 90 - "registrar_salida_screen.dart"
Cohesion: 0.07
Nodes (37): cobro_preview_notifier.dart, ../../../core/utils/print/print_launcher.dart, ../../../core/widgets/tiempo_transcurrido_text.dart, build, CeldaAccionRapidaSheet, _CeldaAccionRapidaSheetState, cobroPreviewNotifierProvider, build (+29 more)

### Community 91 - "turno_list_notifier.dart"
Cohesion: 0.14
Nodes (13): build, cargar, cargarMas, _isLoading, limpiarFiltros, _perPage, refrescar, setEstadoFiltro (+5 more)

### Community 92 - "turno_list_state.dart"
Cohesion: 0.14
Nodes (13): copyWith, desdeFiltro, errorMessage, estadoFiltro, hastaFiltro, hayMas, isLoading, isLoadingMore (+5 more)

### Community 93 - "Notifier"
Cohesion: 0.25
Nodes (8): CeldaGridYaVioDatosNotifier, BuscarPlacaNotifier, BuscarPlacaState, SalidaNotifier, SalidaState, TicketListNotifier, TicketListState, Notifier

### Community 94 - "Sistema de diseño — App de Parqueadero"
Cohesion: 0.18
Nodes (10): Antes de dar por terminada una pantalla, Concepto, Escritura de interfaz, La cuadrícula: bahías pintadas, Movimiento, Paleta, Reglas de color innegociables, Rendimiento de la cuadrícula (+2 more)

### Community 95 - "auth_repository.dart"
Cohesion: 0.40
Nodes (4): login, logout, restoreSession, usuario.dart

### Community 96 - "turno_activo_notifier.dart"
Cohesion: 0.25
Nodes (7): build, cargar, _isLoading, refrescar, TurnoActivoNotifier, TurnoActivoState, turno_activo_state.dart

### Community 97 - "mensualidad_list_notifier.dart"
Cohesion: 0.13
Nodes (14): build, cargar, cargarMas, _isLoading, limpiarFiltros, MensualidadListNotifier, _perPage, reemplazarMensualidad (+6 more)

### Community 98 - "turno_cierre_state.dart"
Cohesion: 0.18
Nodes (10): ../../domain/arqueo_turno.dart, ArqueoTurno, error, resultado, step, TurnoCierreState, TurnoCierreStep, arqueo (+2 more)

### Community 99 - "operador_home_dashboard_test.dart"
Cohesion: 0.14
Nodes (13): Material, package:parqueadero_app/features/auth/presentation/widgets/operador_home_dashboard.dart, authRepository, celda, celdaRepository, main, operador, pumpDashboard (+5 more)

### Community 100 - "horario_repository_test.dart"
Cohesion: 0.22
Nodes (8): dio, _dioError, _horarioJson, _jsonResponse, main, MockDio, repository, requestOptions

### Community 101 - "abrir_turno_screen.dart"
Cohesion: 0.16
Nodes (13): abrir_turno_notifier.dart, FormState, tapFeedback, abrirTurnoNotifierProvider, AbrirTurnoScreen, _AbrirTurnoScreenState, _baseInicialController, build (+5 more)

### Community 102 - "usuario.dart"
Cohesion: 0.14
Nodes (13): admin,, activo, baseInicialTurno, createdAt, email, fromBackend, hashCode, id (+5 more)

### Community 103 - "../domain/celda.dart"
Cohesion: 0.20
Nodes (10): celda_estado_style.dart, ../../domain/celda.dart, EstadoCelda, build, CeldaEstadoBadge, estado, size, build (+2 more)

### Community 104 - "session_notifier.dart"
Cohesion: 0.21
Nodes (11): ../../../core/network/session_events.dart, ../data/auth_repository_impl.dart, sessionEventsProvider, authRepositoryProvider, build, login, logout, _restore (+3 more)

### Community 105 - "upper_case_text_formatter.dart"
Cohesion: 0.50
Nodes (3): formatEditUpdate, UpperCaseTextFormatter, TextInputFormatter

### Community 106 - "turno_repository_impl.dart"
Cohesion: 0.18
Nodes (10): ../domain/turno_repository.dart, dtos/arqueo_turno_dto.dart, dtos/turno_dto.dart, dtos/turno_page_dto.dart, abrir, cerrar, completarArqueo, _dio (+2 more)

### Community 107 - "vehiculo_dto.dart"
Cohesion: 0.17
Nodes (11): ../../domain/vehiculo.dart, createdAt, fromJson, id, placa, propietarioNombre, propietarioTelefono, tipo (+3 more)

### Community 108 - "horario.dart"
Cohesion: 0.15
Nodes (12): int get, apertura, cierre, createdAt, esVigente, hashCode, Horario, id (+4 more)

### Community 109 - "usuario_list_state.dart"
Cohesion: 0.14
Nodes (13): bool?, RolUsuario, activoFiltro, copyWith, errorMessage, hayMas, isLoading, isLoadingMore (+5 more)

### Community 110 - "turnoRepositoryProvider"
Cohesion: 0.48
Nodes (7): turnoRepositoryProvider, abrir, AbrirTurnoNotifier, turnoActivoNotifierProvider, cerrar, TurnoCierreNotifier, _preguntarIniciarTurno

### Community 111 - "usuario_repository.dart"
Cohesion: 0.18
Nodes (10): bool get, actualizar, crear, data, hayMas, listar, page, perPage (+2 more)

### Community 112 - "status_style_test.dart"
Cohesion: 0.14
Nodes (13): dart:math, package:parqueadero_app/core/theme/status_style.dart, b, canal, claro, _contraste, g, la (+5 more)

### Community 113 - "token_storage.dart"
Cohesion: 0.18
Nodes (10): FlutterSecureStorage, _accessTokenKey, clear, readAccessToken, readRefreshToken, _refreshTokenKey, saveTokens, _storage (+2 more)

### Community 114 - "arqueo_summary_view.dart"
Cohesion: 0.08
Nodes (24): diferencia_texto.dart, ../../domain/turno.dart, EstadoTurno, Turno, errorMessage, isLoading, turno, arqueo (+16 more)

### Community 115 - "celda_dto.dart"
Cohesion: 0.18
Nodes (10): CeldaDto, codigo, createdAt, estado, fromJson, id, tipoPermitido, toDomain (+2 more)

### Community 116 - "celda_repository_impl.dart"
Cohesion: 0.20
Nodes (9): ../domain/celda_repository.dart, dtos/celda_dto.dart, dtos/celda_page_dto.dart, CeldaRepositoryImpl, _dio, listarTodas, marcarMantenimiento, _perPage (+1 more)

### Community 117 - "mensualidad_repository.dart"
Cohesion: 0.18
Nodes (10): cancelar, crear, data, hayMas, listar, MensualidadPageResult, page, perPage (+2 more)

### Community 118 - "loading_skeleton.dart"
Cohesion: 0.06
Nodes (37): Animation, AnimationController, double?, AnimatedCountText, build, style, value, borderRadius (+29 more)

### Community 119 - "../../../core/network/api_exception.dart"
Cohesion: 0.11
Nodes (17): buscar_placa_state.dart, ../../celdas/presentation/celda_list_notifier.dart, ../../../core/network/api_exception.dart, ../data/ticket_repository_impl.dart, build, build, registrar, RegistrarEntradaNotifier (+9 more)

### Community 120 - "estado_pago_chip.dart"
Cohesion: 0.33
Nodes (5): estado_pago_style.dart, EstadoPagoMensualidad, build, estado, EstadoPagoChip

### Community 121 - "turno_detail_notifier.dart"
Cohesion: 0.29
Nodes (6): build, cargar, TurnoDetailNotifier, turnoId, TurnoDetailState, turno_detail_state.dart

### Community 122 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 123 - "List"
Cohesion: 0.13
Nodes (13): build, children, FiltrosBar, data, fromJson, meta, page, perPage (+5 more)

### Community 124 - "ticket_abierto_de_celda_notifier.dart"
Cohesion: 0.20
Nodes (8): build, buscar, celdaId, TicketAbiertoDeCeldaNotifier, errorMessage, isLoading, TicketAbiertoDeCeldaState, ticket_abierto_de_celda_state.dart

### Community 125 - "_"
Cohesion: 0.07
Nodes (36): Color, ../../../../core/theme/status_style.dart, IconData, _, color, icon, of, StatusStyle (+28 more)

### Community 126 - "@JsonSerializable"
Cohesion: 0.09
Nodes (22): @JsonSerializable, ../../auth/data/dtos/usuario_dto.dart, accessToken, fromJson, LoginResponseDto, refreshToken, usuario, UsuarioDto (+14 more)

### Community 127 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.06
Nodes (49): ../../../auth/domain/usuario.dart, ../../auth/presentation/session_notifier.dart, ../celda_accion_notifier.dart, celda_estado_badge.dart, ../../../core/theme/app_spacing.dart, ../../../core/widgets/acceso_restringido.dart, ../../../core/widgets/button_spinner.dart, ../../../core/widgets/detail_skeleton.dart (+41 more)

### Community 130 - "Dio"
Cohesion: 0.29
Nodes (7): Dio, MockDio, MockDio, MockDio, MockDio, MockDio, MockDio

### Community 131 - "tarifa_page_dto.dart"
Cohesion: 0.20
Nodes (9): data, fromJson, meta, page, perPage, TarifaPageDto, TarifaPageMetaDto, total (+1 more)

### Community 132 - "package:dio/dio.dart"
Cohesion: 0.08
Nodes (25): auth_interceptor.dart, Completer, ../config/app_config.dart, ../../features/auth/data/dtos/refresh_response_dto.dart, ../../features/auth/data/token_storage.dart, Interceptor, config, dio (+17 more)

### Community 133 - "session_events.dart"
Cohesion: 0.25
Nodes (8): _controller, dispose, emit, events, SessionEvents, SessionEventType, stream, Stream

### Community 134 - "mensualidad_filtros_bar.dart"
Cohesion: 0.19
Nodes (12): mensualidadListNotifierProvider, build, build, createState, dispose, initState, MensualidadFiltrosBar, _MensualidadFiltrosBarState (+4 more)

### Community 135 - "validators.dart"
Cohesion: 0.08
Nodes (23): ../domain/tipo_vehiculo.dart, null, _placaCarroRegex, _placaMotoActualRegex, _placaMotoAntiguaRegex, tipoVehiculoDePlaca, tipoVehiculoIcon, tipoVehiculoLabel (+15 more)

### Community 137 - "AGENTS.md"
Cohesion: 0.50
Nodes (3): No negociable, Relación con el otro proyecto, Verificación antes de entregar

### Community 138 - "_"
Cohesion: 0.29
Nodes (8): _, AppColors, asfalto, concreto, demarcacion, linea, tinta, verdeSenal

### Community 139 - "_"
Cohesion: 0.29
Nodes (8): _, AppSpacing, gutter, lg, md, sm, xl, xs

### Community 140 - "celda_detail_screen_test.dart"
Cohesion: 0.03
Nodes (69): MockTicketRepository, package:fake_async/fake_async.dart, package:parqueadero_app/features/celdas/presentation/celda_detail_screen.dart, package:parqueadero_app/features/tickets/data/ticket_repository_impl.dart, package:parqueadero_app/features/tickets/domain/cobro_preview.dart, package:parqueadero_app/features/tickets/domain/ticket.dart, package:parqueadero_app/features/tickets/domain/ticket_repository.dart, package:parqueadero_app/features/tickets/presentation/buscar_placa_notifier.dart (+61 more)

### Community 141 - "mensualidad_repository_test.dart"
Cohesion: 0.22
Nodes (8): MockDio, dio, _dioError, _jsonResponse, main, _mensualidadJson, repository, requestOptions

### Community 142 - "_"
Cohesion: 0.33
Nodes (7): _, AppMotion, curve, effective, fast, medium, slow

### Community 144 - "recibo_view.dart"
Cohesion: 0.20
Nodes (9): desglose_view.dart, ../../domain/recibo.dart, Recibo, build, kReciboAnchoMm80, _pieStyle, recibo, ReciboView (+1 more)

### Community 145 - "app_page_transitions.dart"
Cohesion: 0.22
Nodes (8): app_motion.dart, Duration get, AppPageTransitionsBuilder, reverseTransitionDuration, transitionDuration, Offset, PageTransitionsBuilder, T

### Community 146 - "../../../../core/utils/tipo_vehiculo_label.dart"
Cohesion: 0.25
Nodes (8): ../../../../core/utils/tipo_vehiculo_label.dart, ../../domain/tarifa.dart, tarifaListNotifierProvider, build, build, TarifaFiltrosBar, Route /tarifas/nueva, main

### Community 148 - "build"
Cohesion: 0.50
Nodes (4): build, Route /turnos/abrir, main, pumpAbrirTurnoScreen

### Community 150 - "_"
Cohesion: 0.40
Nodes (6): _, AppBreakpoints, contentMaxWidth, gridMaxWidth, mobile, tablet

### Community 151 - "static const"
Cohesion: 0.28
Nodes (9): _, AppElevation, flat, low, raised, _, AppTypography, montoDestacado (+1 more)

### Community 152 - "horario_repository_impl.dart"
Cohesion: 0.20
Nodes (9): ../domain/horario_repository.dart, dtos/horario_dto.dart, dtos/horario_page_dto.dart, actualizar, cerrar, crear, _dio, listarTodas (+1 more)

### Community 154 - "seleccionar_hora.dart"
Cohesion: 0.33
Nodes (5): formatHora, SeleccionarHora, seleccionarHoraPorDefecto, showTimePicker, typedef

### Community 156 - "_"
Cohesion: 0.50
Nodes (5): _, color, label, of, VigenciaStyle

### Community 157 - "_"
Cohesion: 0.50
Nodes (5): _, AppRadius, lg, md, sm

### Community 159 - "tarifa_list_state.dart"
Cohesion: 0.29
Nodes (6): copyWith, errorMessage, isLoading, tarifas, tipoFiltro, _unset

### Community 161 - "_"
Cohesion: 0.29
Nodes (8): Usuario, _, authenticated, checking, SessionStatus, status, unauthenticated, usuario

### Community 162 - "elapsed_time.dart"
Cohesion: 0.50
Nodes (3): formatElapsed, horas, minutos

### Community 173 - "turno_repository_test.dart"
Cohesion: 0.20
Nodes (9): TurnoRepositoryImpl, _arqueoJson, dio, _dioError, _jsonResponse, main, repository, requestOptions (+1 more)

### Community 174 - "NuevaTarifaNotifier"
Cohesion: 0.40
Nodes (4): NuevaTarifaNotifier, errorMessage, isLoading, NuevaTarifaState

### Community 175 - "tarifa_accion_notifier.dart"
Cohesion: 0.20
Nodes (9): ../data/tarifa_repository_impl.dart, build, crear, actualizar, build, tarifaId, nueva_tarifa_state.dart, tarifa_accion_state.dart (+1 more)

### Community 177 - "TarifaAccionNotifier"
Cohesion: 0.40
Nodes (4): TarifaAccionNotifier, errorMessage, isLoading, TarifaAccionState

### Community 179 - "../../domain/mensualidad.dart"
Cohesion: 0.20
Nodes (8): ../../domain/mensualidad.dart, build, crear, NuevaMensualidadNotifier, errorMessage, isLoading, NuevaMensualidadState, nueva_mensualidad_state.dart

### Community 182 - "abrir_turno_state.dart"
Cohesion: 0.50
Nodes (3): AbrirTurnoState, errorMessage, isLoading

## Knowledge Gaps
- **1770 isolated node(s):** `AppConfig`, `apiBaseUrl`, `appConfigProvider`, `fromEnvironment`, `otro` (+1765 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2080 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `_` to `package:flutter/material.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `TipoVehiculo` connect `vehiculo.dart` to `nueva_mensualidad_screen.dart`, `registrar_entrada_screen.dart`, `tarifa_grupo_card.dart`, `tarifa.dart`, `celda_list_state.dart`, `celda.dart`, `nueva_tarifa_screen.dart`, `recibo.dart`, `tarifa_list_state.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Why does `AuthRepository` connect `Mock` to `MockAuthRepository`, `package:parqueadero_app/features/auth/data/auth_repository_impl.dart`, `celda_detail_screen_test.dart`, `nuevo_horario_screen_test.dart`, `login_screen_test.dart`, `package:mocktail/mocktail.dart`, `package:flutter_test/flutter_test.dart`, `celda_card_test.dart`, `auth_repository_impl.dart`, `package:parqueadero_app/core/network/api_exception.dart`, `auth_repository.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **What connects `AppConfig`, `apiBaseUrl`, `appConfigProvider` to the rest of the system?**
  _1770 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `MockAuthRepository` be split into smaller, more focused modules?**
  _Cohesion score 0.029605263157894735 - nodes in this community are weakly interconnected._
- **Should `usuario_detail_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.056025369978858354 - nodes in this community are weakly interconnected._
- **Should `turno_kpis_view.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07142857142857142 - nodes in this community are weakly interconnected._