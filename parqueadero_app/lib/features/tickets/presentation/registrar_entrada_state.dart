class RegistrarEntradaState {
  const RegistrarEntradaState({this.isLoading = false, this.errorMessage, this.errorCode});

  final bool isLoading;
  final String? errorMessage;

  /// `code` del `ApiException` que produjo [errorMessage], si fue un error
  /// del backend (`null` para `NetworkException` — sin `code`, sin
  /// respuesta del servidor — o cuando no hay error). Lo usa
  /// `RegistrarEntradaScreen` para decidir, en el flujo sin celda
  /// preseleccionada, si vale la pena reintentar con otra celda LIBRE del
  /// mismo tipo (p.ej. `CELDA_RESERVADA_MENSUALIDAD`) o si el problema no
  /// depende de la celda (p.ej. `TARIFA_NO_VIGENTE`).
  final String? errorCode;
}
