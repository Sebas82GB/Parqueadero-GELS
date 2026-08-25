import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/ticket_repository_impl.dart';
import 'cobro_preview_state.dart';

/// Refresca `GET /tickets/:id/preview-cobro` cada 30s mientras la pantalla de
/// salida esté abierta, mismo intervalo que el timer de "tiempo transcurrido"
/// de esa misma pantalla y que el poll de `CeldaListNotifier` — no es un
/// valor nuevo, es consistencia con lo que ya existe.
///
/// A diferencia de `CeldaListNotifier`, un error de fondo no siempre se trata
/// igual: `TICKET_NO_ABIERTO`/`TICKET_NO_ENCONTRADO` significan que el
/// ticket lo cerró o anuló otro operador mientras esta pantalla seguía
/// abierta — ahí no tiene sentido reintentar cada 30s, así que el timer se
/// cancela y queda `esTerminal` para que la pantalla bloquee "Registrar
/// salida". Cualquier otro error (red, timeout) se trata como
/// `CeldaListNotifier`: si ya había un preview en pantalla, se conserva sin
/// tapar la vista con un error.
class CobroPreviewNotifier extends Notifier<CobroPreviewState> {
  CobroPreviewNotifier(this.ticketId);

  final String ticketId;

  static const _codigosTerminales = {'TICKET_NO_ABIERTO', 'TICKET_NO_ENCONTRADO'};

  Timer? _timer;
  bool _isRefreshing = false;

  @override
  CobroPreviewState build() {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refrescar());
    // Mismo motivo que en `CeldaListNotifier.build()`: `refrescar()` lee
    // `state` antes de su primer await, así que hay que diferirlo a después
    // de que este `build()` termine de fijar el estado inicial.
    Future.microtask(refrescar);
    return const CobroPreviewState(isLoading: true);
  }

  Future<void> refrescar() async {
    if (_isRefreshing || state.esTerminal) return;
    _isRefreshing = true;
    final huboDatosPrevios = state.preview != null;
    if (!huboDatosPrevios) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final preview = await ref.read(ticketRepositoryProvider).previsualizarCobro(ticketId);
      if (!ref.mounted) return;
      state = state.copyWith(preview: preview, isLoading: false, clearError: true);
    } on ApiException catch (e) {
      if (!ref.mounted) return;
      if (_codigosTerminales.contains(e.code)) {
        _timer?.cancel();
        state = state.copyWith(isLoading: false, error: e, esTerminal: true);
      } else {
        state = state.copyWith(isLoading: false, error: e, clearError: huboDatosPrevios);
      }
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e, clearError: huboDatosPrevios);
    } finally {
      _isRefreshing = false;
    }
  }
}

final cobroPreviewNotifierProvider = NotifierProvider.autoDispose
    .family<CobroPreviewNotifier, CobroPreviewState, String>(CobroPreviewNotifier.new);
