import '../domain/turno.dart';

const Object _unset = Object();

class TurnoListState {
  const TurnoListState({
    this.turnos = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.page = 1,
    this.total = 0,
    this.estadoFiltro,
    this.operadorIdFiltro,
    this.desdeFiltro,
    this.hastaFiltro,
  });

  final List<Turno> turnos;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int page;
  final int total;
  final EstadoTurno? estadoFiltro;
  final String? operadorIdFiltro;
  final DateTime? desdeFiltro;
  final DateTime? hastaFiltro;

  bool get hayMas => turnos.length < total;

  TurnoListState copyWith({
    List<Turno>? turnos,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    int? page,
    int? total,
    Object? estadoFiltro = _unset,
    Object? operadorIdFiltro = _unset,
    Object? desdeFiltro = _unset,
    Object? hastaFiltro = _unset,
  }) => TurnoListState(
    turnos: turnos ?? this.turnos,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    page: page ?? this.page,
    total: total ?? this.total,
    estadoFiltro: identical(estadoFiltro, _unset) ? this.estadoFiltro : estadoFiltro as EstadoTurno?,
    operadorIdFiltro: identical(operadorIdFiltro, _unset) ? this.operadorIdFiltro : operadorIdFiltro as String?,
    desdeFiltro: identical(desdeFiltro, _unset) ? this.desdeFiltro : desdeFiltro as DateTime?,
    hastaFiltro: identical(hastaFiltro, _unset) ? this.hastaFiltro : hastaFiltro as DateTime?,
  );
}
