import '../../../core/network/api_exception.dart';
import '../domain/ticket.dart';

enum SalidaStep { formulario, enviando, exito }

class SalidaState {
  const SalidaState({this.step = SalidaStep.formulario, this.error, this.ticketCerrado});

  final SalidaStep step;

  /// Tipado (no solo `String`) para que la UI decida si ofrece "Abrir turno"
  /// según `error.code`, sin perder la regla de mostrar `.message` tal cual
  /// para el resto de los casos. Mismo patrón que `LoginState.error`.
  final AppException? error;

  /// Solo distinto de `null` cuando `step == exito`.
  final Ticket? ticketCerrado;
}
