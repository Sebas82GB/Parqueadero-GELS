import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/ticket_repository_impl.dart';
import '../domain/ticket.dart';
import 'ticket_list_state.dart';

const _perPage = 20;

/// Historial: a diferencia de `CeldaListNotifier`, sin `Timer.periodic`. Es
/// una consulta puntual que el operador dispara y revisa, se refresca con
/// pull-to-refresh o al cambiar un filtro, no en tiempo real.
class TicketListNotifier extends Notifier<TicketListState> {
  bool _isLoading = false;

  @override
  TicketListState build() {
    Future.microtask(() => cargar(reset: true));
    return const TicketListState(isLoading: true);
  }

  Future<void> cargar({bool reset = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    if (reset) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final pagina = await ref
          .read(ticketRepositoryProvider)
          .listar(
            estado: state.estadoFiltro,
            placa: state.placaFiltro,
            desde: state.desdeFiltro,
            hasta: state.hastaFiltro,
            page: 1,
            perPage: _perPage,
          );
      if (!ref.mounted) return;
      state = state.copyWith(
        tickets: pagina.data,
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
          .read(ticketRepositoryProvider)
          .listar(
            estado: state.estadoFiltro,
            placa: state.placaFiltro,
            desde: state.desdeFiltro,
            hasta: state.hastaFiltro,
            page: state.page + 1,
            perPage: _perPage,
          );
      if (!ref.mounted) return;
      // Un fallo al cargar más páginas no borra ni tapa la lista ya visible.
      state = state.copyWith(
        tickets: [...state.tickets, ...pagina.data],
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

  void setEstadoFiltro(EstadoTicket? estado) {
    state = state.copyWith(estadoFiltro: estado);
    cargar(reset: true);
  }

  void setPlacaFiltro(String? placa) {
    state = state.copyWith(placaFiltro: (placa == null || placa.isEmpty) ? null : placa);
    cargar(reset: true);
  }

  void setRangoFechas(DateTime? desde, DateTime? hasta) {
    state = state.copyWith(desdeFiltro: desde, hastaFiltro: hasta);
    cargar(reset: true);
  }

  void limpiarFiltros() {
    state = state.copyWith(estadoFiltro: null, placaFiltro: null, desdeFiltro: null, hastaFiltro: null);
    cargar(reset: true);
  }
}

final ticketListNotifierProvider =
    NotifierProvider.autoDispose<TicketListNotifier, TicketListState>(TicketListNotifier.new);
