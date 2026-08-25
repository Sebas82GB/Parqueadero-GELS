import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/turno_repository_impl.dart';
import '../domain/turno.dart';
import 'turno_list_state.dart';

const _perPage = 20;

/// Historial: consulta puntual que se refresca con pull-to-refresh o al
/// cambiar un filtro, mismo espíritu que `TicketListNotifier`. El filtro por
/// `operadorId` no necesita distinguir rol acá: si quien consulta es
/// OPERADOR, el backend fuerza su propio id sin importar qué se mande.
class TurnoListNotifier extends Notifier<TurnoListState> {
  bool _isLoading = false;

  @override
  TurnoListState build() {
    Future.microtask(() => cargar(reset: true));
    return const TurnoListState(isLoading: true);
  }

  Future<void> cargar({bool reset = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    if (reset) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final pagina = await ref
          .read(turnoRepositoryProvider)
          .listar(
            operadorId: state.operadorIdFiltro,
            estado: state.estadoFiltro,
            desde: state.desdeFiltro,
            hasta: state.hastaFiltro,
            page: 1,
            perPage: _perPage,
          );
      if (!ref.mounted) return;
      state = state.copyWith(
        turnos: pagina.data,
        isLoading: false,
        page: pagina.page,
        total: pagina.total,
        clearError: true,
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> cargarMas() async {
    if (_isLoading || !state.hayMas) return;
    _isLoading = true;
    state = state.copyWith(isLoadingMore: true);
    try {
      final pagina = await ref
          .read(turnoRepositoryProvider)
          .listar(
            operadorId: state.operadorIdFiltro,
            estado: state.estadoFiltro,
            desde: state.desdeFiltro,
            hasta: state.hastaFiltro,
            page: state.page + 1,
            perPage: _perPage,
          );
      if (!ref.mounted) return;
      // Un fallo al cargar más páginas no borra ni tapa la lista ya visible.
      state = state.copyWith(
        turnos: [...state.turnos, ...pagina.data],
        isLoadingMore: false,
        page: pagina.page,
        total: pagina.total,
      );
    } on AppException catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoadingMore: false);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refrescar() => cargar(reset: true);

  void setEstadoFiltro(EstadoTurno? estado) {
    state = state.copyWith(estadoFiltro: estado);
    cargar(reset: true);
  }

  void setOperadorIdFiltro(String? operadorId) {
    state = state.copyWith(operadorIdFiltro: (operadorId == null || operadorId.isEmpty) ? null : operadorId);
    cargar(reset: true);
  }

  void setRangoFechas(DateTime? desde, DateTime? hasta) {
    state = state.copyWith(desdeFiltro: desde, hastaFiltro: hasta);
    cargar(reset: true);
  }

  void limpiarFiltros() {
    state = state.copyWith(estadoFiltro: null, operadorIdFiltro: null, desdeFiltro: null, hastaFiltro: null);
    cargar(reset: true);
  }
}

final turnoListNotifierProvider =
    NotifierProvider.autoDispose<TurnoListNotifier, TurnoListState>(TurnoListNotifier.new);
