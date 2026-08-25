import '../domain/mensualidad.dart';

const Object _unset = Object();

class MensualidadListState {
  const MensualidadListState({
    this.mensualidades = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.page = 1,
    this.total = 0,
    this.estadoPagoFiltro,
    this.placaFiltro,
    this.vigenciaFiltro,
  });

  final List<Mensualidad> mensualidades;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int page;
  final int total;
  final EstadoPagoMensualidad? estadoPagoFiltro;
  final String? placaFiltro;
  final VigenciaMensualidad? vigenciaFiltro;

  bool get hayMas => mensualidades.length < total;

  MensualidadListState copyWith({
    List<Mensualidad>? mensualidades,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    int? page,
    int? total,
    Object? estadoPagoFiltro = _unset,
    Object? placaFiltro = _unset,
    Object? vigenciaFiltro = _unset,
  }) => MensualidadListState(
    mensualidades: mensualidades ?? this.mensualidades,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    page: page ?? this.page,
    total: total ?? this.total,
    estadoPagoFiltro: identical(estadoPagoFiltro, _unset)
        ? this.estadoPagoFiltro
        : estadoPagoFiltro as EstadoPagoMensualidad?,
    placaFiltro: identical(placaFiltro, _unset) ? this.placaFiltro : placaFiltro as String?,
    vigenciaFiltro: identical(vigenciaFiltro, _unset)
        ? this.vigenciaFiltro
        : vigenciaFiltro as VigenciaMensualidad?,
  );
}
