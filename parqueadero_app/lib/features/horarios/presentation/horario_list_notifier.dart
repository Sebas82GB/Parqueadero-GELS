import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/horario_repository_impl.dart';
import 'horario_list_state.dart';

/// Sin `Timer.periodic`: solo el ADMIN cambia el horario y lo hace desde esta
/// misma pantalla, no hay actividad de fondo de otros roles que requiera
/// refrescar en tiempo real (mismo criterio que `TarifaListNotifier`).
class HorarioListNotifier extends Notifier<HorarioListState> {
  bool _isLoading = false;

  @override
  HorarioListState build() {
    Future.microtask(refrescar);
    return const HorarioListState(isLoading: true);
  }

  Future<void> refrescar() async {
    if (_isLoading) return;
    _isLoading = true;
    final huboDatosPrevios = state.horarios.isNotEmpty;
    if (!huboDatosPrevios) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final horarios = await ref.read(horarioRepositoryProvider).listarTodas();
      if (!ref.mounted) return;
      state = state.copyWith(horarios: horarios, isLoading: false, clearError: true);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      // Un refresh de fondo fallido (pull-to-refresh) con datos ya en
      // pantalla no tapa la lista con el error-state.
      state = state.copyWith(isLoading: false, errorMessage: huboDatosPrevios ? null : e.message);
    } finally {
      _isLoading = false;
    }
  }
}

final horarioListNotifierProvider =
    NotifierProvider.autoDispose<HorarioListNotifier, HorarioListState>(HorarioListNotifier.new);
