import '../../../core/network/api_exception.dart';
import '../domain/arqueo_turno.dart';

enum TurnoCierreStep { formulario, enviando, exito }

class TurnoCierreState {
  const TurnoCierreState({this.step = TurnoCierreStep.formulario, this.error, this.resultado});

  final TurnoCierreStep step;

  /// Tipado (no solo `String`), mismo patrón que `SalidaState.error`.
  final AppException? error;

  /// Solo distinto de `null` cuando `step == exito`. Backend ya lo entrega
  /// completo en la misma respuesta del cierre — la pantalla no vuelve a
  /// pedirlo.
  final ArqueoTurno? resultado;
}
