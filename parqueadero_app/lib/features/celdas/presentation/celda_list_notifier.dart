import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/celda_repository_impl.dart';
import '../domain/celda.dart';
import 'celda_list_state.dart';

/// `autoDispose`: el timer de refresco de 30s (ver [build]) debe cancelarse
/// cuando el usuario sale de la pantalla de celdas, no solo cuando cierra la
/// app. Con un provider normal el notifier viviría toda la sesión y el
/// polling seguiría corriendo en segundo plano aunque nadie lo esté viendo.
class CeldaListNotifier extends Notifier<CeldaListState> {
  Timer? _pollTimer;
  bool _isRefreshing = false;

  @override
  CeldaListState build() {
    ref.onDispose(() => _pollTimer?.cancel());
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => refrescar());
    // `refrescar()` lee `state` en su prefijo síncrono (antes del primer
    // await); llamarla directamente aquí lo haría antes de que Riverpod
    // termine de inicializar el estado con el valor que retorna `build()`.
    // Un microtask la difiere a después de eso, sin esperar los 30s del timer.
    Future.microtask(refrescar);
    return const CeldaListState(isLoading: true);
  }

  /// Usado por el timer de 30s Y por el pull-to-refresh: el guard evita
  /// disparar dos GETs en paralelo si coinciden.
  Future<void> refrescar() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    final huboDatosPrevios = state.celdas.isNotEmpty;
    if (!huboDatosPrevios) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final celdas = await ref.read(celdaRepositoryProvider).listarTodas();
      if (!ref.mounted) return;
      state = state.copyWith(celdas: celdas, isLoading: false, clearError: true);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      // Un refresh de fondo fallido (timer o pull-to-refresh) con datos ya
      // en pantalla no tapa el grid con el error-state: solo se refleja si
      // ya no hay nada que mostrar.
      state = state.copyWith(isLoading: false, errorMessage: huboDatosPrevios ? null : e.message);
    } finally {
      _isRefreshing = false;
    }
  }

  void setZonaFiltro(String? zona) => state = state.copyWith(zonaFiltro: zona);

  void setEstadoFiltro(EstadoCelda? estado) => state = state.copyWith(estadoFiltro: estado);

  void setTipoFiltro(TipoVehiculo? tipo) => state = state.copyWith(tipoFiltro: tipo);

  void limpiarFiltros() =>
      state = state.copyWith(zonaFiltro: null, estadoFiltro: null, tipoFiltro: null);

  /// Parchea localmente una celda tras una acción exitosa del detalle, para
  /// no esperar al próximo poll de 30s.
  void reemplazarCelda(Celda actualizada) => state = state.copyWith(
    celdas: [for (final c in state.celdas) if (c.id == actualizada.id) actualizada else c],
  );
}

final celdaListNotifierProvider =
    NotifierProvider.autoDispose<CeldaListNotifier, CeldaListState>(CeldaListNotifier.new);
