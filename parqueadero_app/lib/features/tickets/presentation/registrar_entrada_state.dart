import '../../../core/network/api_exception.dart';

class RegistrarEntradaState {
  const RegistrarEntradaState({this.isLoading = false, this.error});

  final bool isLoading;

  /// Tipado (no solo `String`) para que `ErrorBanner` pueda mostrar también
  /// `details` (p.ej. el motivo exacto de un `400 VALIDATION_ERROR` sobre la
  /// placa), sin perder la regla de mostrar `.message` tal cual para el
  /// resto de los casos. Mismo patrón que `SalidaState.error`.
  final AppException? error;

  /// `code` del `ApiException` que produjo [error], si fue un error del
  /// backend (`null` para `NetworkException` — sin `code`, sin respuesta del
  /// servidor — o cuando no hay error). Lo usa `RegistrarEntradaScreen` para
  /// decidir, en el flujo sin celda preseleccionada, si vale la pena
  /// reintentar con otra celda LIBRE del mismo tipo (p.ej.
  /// `CELDA_RESERVADA_MENSUALIDAD`) o si el problema no depende de la celda
  /// (p.ej. `TARIFA_NO_VIGENTE`).
  String? get errorCode => error is ApiException ? (error as ApiException).code : null;
}
