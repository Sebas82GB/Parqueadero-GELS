import '../domain/celda.dart';

/// Sentinel para distinguir "no pasar este parámetro" de "pasarlo como
/// null" en [CeldaListState.copyWith] — así se puede limpiar un filtro.
const Object _unset = Object();

class CeldaListState {
  const CeldaListState({
    this.celdas = const [],
    this.isLoading = false,
    this.errorMessage,
    this.zonaFiltro,
    this.estadoFiltro,
    this.tipoFiltro,
  });

  /// Lista COMPLETA de celdas, sin filtrar.
  final List<Celda> celdas;
  final bool isLoading;
  final String? errorMessage;
  final String? zonaFiltro;
  final EstadoCelda? estadoFiltro;
  final TipoVehiculo? tipoFiltro;

  CeldaListState copyWith({
    List<Celda>? celdas,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Object? zonaFiltro = _unset,
    Object? estadoFiltro = _unset,
    Object? tipoFiltro = _unset,
  }) => CeldaListState(
    celdas: celdas ?? this.celdas,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    zonaFiltro: identical(zonaFiltro, _unset) ? this.zonaFiltro : zonaFiltro as String?,
    estadoFiltro: identical(estadoFiltro, _unset) ? this.estadoFiltro : estadoFiltro as EstadoCelda?,
    tipoFiltro: identical(tipoFiltro, _unset) ? this.tipoFiltro : tipoFiltro as TipoVehiculo?,
  );

  int get totalCeldas => celdas.length;

  /// Sobre la lista COMPLETA: el contador total siempre refleja la
  /// disponibilidad real, no la vista filtrada.
  int get totalLibres => celdas.where((c) => c.estado == EstadoCelda.libre).length;

  int get totalOcupadas => celdas.where((c) => c.estado == EstadoCelda.ocupada).length;

  int get totalMantenimiento =>
      celdas.where((c) => c.estado == EstadoCelda.mantenimiento).length;

  List<Celda> get celdasFiltradas => celdas
      .where(
        (c) =>
            (zonaFiltro == null || c.zona == zonaFiltro) &&
            (estadoFiltro == null || c.estado == estadoFiltro) &&
            (tipoFiltro == null || c.tipoPermitido == tipoFiltro),
      )
      .toList();

  List<String> get zonas => celdas.map((c) => c.zona).toSet().toList()..sort();

  /// Conteo de una zona SIN los filtros activos: el header de zona siempre
  /// muestra la disponibilidad real de esa zona, igual que el total.
  int librresEnZona(String zona) =>
      celdas.where((c) => c.zona == zona && c.estado == EstadoCelda.libre).length;

  int ocupadasEnZona(String zona) =>
      celdas.where((c) => c.zona == zona && c.estado == EstadoCelda.ocupada).length;

  int mantenimientoEnZona(String zona) =>
      celdas.where((c) => c.zona == zona && c.estado == EstadoCelda.mantenimiento).length;

  int totalEnZona(String zona) => celdas.where((c) => c.zona == zona).length;

  /// Celdas filtradas, agrupadas por zona en orden alfabético. Una zona sin
  /// celdas que coincidan con el filtro no aparece en el mapa.
  Map<String, List<Celda>> get celdasFiltradasPorZona {
    final filtradas = celdasFiltradas;
    return {
      for (final z in zonas)
        if (filtradas.any((c) => c.zona == z)) z: filtradas.where((c) => c.zona == z).toList(),
    };
  }
}
