import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/mensualidad_repository_impl.dart';
import '../domain/mensualidad.dart';
import 'mensualidad_list_state.dart';

const _perPage = 20;

/// Mismo patrón que `TicketListNotifier`: sin polling, paginación real
/// contra el backend. `vigenciaFiltro` viaja como query param real (no un
/// filtro solo visual sobre la página ya traída): filtrar en el cliente
/// sobre una página parcial rompería `meta.total` y "cargar más".
class MensualidadListNotifier extends Notifier<MensualidadListState> {
  bool _isLoading = false;

  @override
  MensualidadListState build() {
    Future.microtask(() => cargar(reset: true));
    return const MensualidadListState(isLoading: true);
  }

  Future<void> cargar({bool reset = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    if (reset) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final pagina = await ref
          .read(mensualidadRepositoryProvider)
          .listar(
            estadoPago: state.estadoPagoFiltro,
            placa: state.placaFiltro,
            vigencia: state.vigenciaFiltro,
            page: 1,
            perPage: _perPage,
          );
      if (!ref.mounted) return;
      state = state.copyWith(
        mensualidades: pagina.data,
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
          .read(mensualidadRepositoryProvider)
          .listar(
            estadoPago: state.estadoPagoFiltro,
            placa: state.placaFiltro,
            vigencia: state.vigenciaFiltro,
            page: state.page + 1,
            perPage: _perPage,
          );
      if (!ref.mounted) return;
      state = state.copyWith(
        mensualidades: [...state.mensualidades, ...pagina.data],
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

  void setEstadoPagoFiltro(EstadoPagoMensualidad? estado) {
    state = state.copyWith(estadoPagoFiltro: estado);
    cargar(reset: true);
  }

  void setPlacaFiltro(String? placa) {
    state = state.copyWith(placaFiltro: (placa == null || placa.isEmpty) ? null : placa);
    cargar(reset: true);
  }

  void setVigenciaFiltro(VigenciaMensualidad? vigencia) {
    state = state.copyWith(vigenciaFiltro: vigencia);
    cargar(reset: true);
  }

  void limpiarFiltros() {
    state = state.copyWith(estadoPagoFiltro: null, placaFiltro: null, vigenciaFiltro: null);
    cargar(reset: true);
  }

  /// Parcha localmente una mensualidad tras una acción exitosa del detalle
  /// (cancelar), para no esperar a la próxima recarga manual.
  void reemplazarMensualidad(Mensualidad actualizada) => state = state.copyWith(
    mensualidades: [
      for (final m in state.mensualidades) if (m.id == actualizada.id) actualizada else m,
    ],
  );
}

final mensualidadListNotifierProvider =
    NotifierProvider.autoDispose<MensualidadListNotifier, MensualidadListState>(
      MensualidadListNotifier.new,
    );
