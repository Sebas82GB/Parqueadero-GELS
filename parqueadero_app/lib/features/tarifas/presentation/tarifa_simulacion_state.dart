class TarifaSimulacionState {
  const TarifaSimulacionState({
    this.isLoading = false,
    this.valorTotal,
    this.tieneResultado = false,
    this.errorMessage,
  });

  final bool isLoading;

  /// Null tanto si todavía no se ha simulado nada como si se simuló y el
  /// tipo de vehículo es OTRO (sin cálculo automático). [tieneResultado]
  /// distingue esos dos casos.
  final int? valorTotal;
  final bool tieneResultado;
  final String? errorMessage;
}
