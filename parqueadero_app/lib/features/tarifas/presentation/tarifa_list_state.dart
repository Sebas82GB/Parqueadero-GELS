import '../domain/tarifa.dart';

/// Sentinel para distinguir "no pasar este parámetro" de "pasarlo como
/// null" en [TarifaListState.copyWith] — así se puede limpiar el filtro.
const Object _unset = Object();

class TarifaListState {
  const TarifaListState({this.tarifas = const [], this.isLoading = false, this.errorMessage, this.tipoFiltro});

  /// Lista COMPLETA de tarifas (vigentes e histórico), sin filtrar.
  final List<Tarifa> tarifas;
  final bool isLoading;
  final String? errorMessage;
  final TipoVehiculo? tipoFiltro;

  TarifaListState copyWith({
    List<Tarifa>? tarifas,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Object? tipoFiltro = _unset,
  }) => TarifaListState(
    tarifas: tarifas ?? this.tarifas,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    tipoFiltro: identical(tipoFiltro, _unset) ? this.tipoFiltro : tipoFiltro as TipoVehiculo?,
  );

  /// Tarifas (ya filtradas por [tipoFiltro] si hay uno activo), agrupadas por
  /// tipo de vehículo en el orden de `TipoVehiculo.values`. Cada grupo queda
  /// ordenado por `vigenteDesde` descendente, así que la vigente (si la hay)
  /// siempre cae primera. Un tipo sin tarifas tras filtrar no aparece en el
  /// mapa.
  Map<TipoVehiculo, List<Tarifa>> get tarifasFiltradasPorTipo {
    final filtradas = tipoFiltro == null
        ? tarifas
        : tarifas.where((t) => t.tipoVehiculo == tipoFiltro).toList();
    final resultado = <TipoVehiculo, List<Tarifa>>{};
    for (final tipo in TipoVehiculo.values) {
      final grupo = filtradas.where((t) => t.tipoVehiculo == tipo).toList()
        ..sort((a, b) => b.vigenteDesde.compareTo(a.vigenteDesde));
      if (grupo.isNotEmpty) resultado[tipo] = grupo;
    }
    return resultado;
  }
}
