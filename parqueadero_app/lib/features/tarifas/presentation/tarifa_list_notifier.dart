import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/tarifa_repository_impl.dart';
import '../domain/tarifa.dart';
import 'tarifa_list_state.dart';

/// A diferencia de `CeldaListNotifier`, sin `Timer.periodic`: solo el ADMIN
/// cambia las tarifas y lo hace desde esta misma pantalla, no hay actividad
/// de fondo de otros roles que requiera refrescar en tiempo real.
class TarifaListNotifier extends Notifier<TarifaListState> {
  bool _isLoading = false;

  @override
  TarifaListState build() {
    Future.microtask(refrescar);
    return const TarifaListState(isLoading: true);
  }

  Future<void> refrescar() async {
    if (_isLoading) return;
    _isLoading = true;
    final huboDatosPrevios = state.tarifas.isNotEmpty;
    if (!huboDatosPrevios) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final tarifas = await ref.read(tarifaRepositoryProvider).listarTodas();
      if (!ref.mounted) return;
      state = state.copyWith(tarifas: tarifas, isLoading: false, clearError: true);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      // Un refresh de fondo fallido (pull-to-refresh) con datos ya en
      // pantalla no tapa la lista con el error-state.
      state = state.copyWith(isLoading: false, errorMessage: huboDatosPrevios ? null : e.message);
    } finally {
      _isLoading = false;
    }
  }

  void setTipoFiltro(TipoVehiculo? tipo) => state = state.copyWith(tipoFiltro: tipo);
}

final tarifaListNotifierProvider =
    NotifierProvider.autoDispose<TarifaListNotifier, TarifaListState>(TarifaListNotifier.new);
