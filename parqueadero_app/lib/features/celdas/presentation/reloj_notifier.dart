import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reloj compartido para "tiempo transcurrido" en celdas OCUPADAS: un solo
/// `Timer.periodic` para toda la pantalla, no uno por tarjeta. `autoDispose`
/// porque solo lo observan las tarjetas ocupadas mientras esta pantalla está
/// montada — el timer se cancela apenas nada lo observa (se sale de celdas),
/// mismo patrón que el poll de 30s en `celda_list_notifier.dart`.
class RelojNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => state = DateTime.now());
    ref.onDispose(() => _timer?.cancel());
    return DateTime.now();
  }
}

final relojNotifierProvider = NotifierProvider.autoDispose<RelojNotifier, DateTime>(RelojNotifier.new);
