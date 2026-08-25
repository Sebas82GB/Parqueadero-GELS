import '../domain/ticket.dart';

const Object _unset = Object();

class TicketListState {
  const TicketListState({
    this.tickets = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.page = 1,
    this.total = 0,
    this.estadoFiltro,
    this.placaFiltro,
    this.desdeFiltro,
    this.hastaFiltro,
  });

  final List<Ticket> tickets;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int page;
  final int total;
  final EstadoTicket? estadoFiltro;
  final String? placaFiltro;
  final DateTime? desdeFiltro;
  final DateTime? hastaFiltro;

  bool get hayMas => tickets.length < total;

  TicketListState copyWith({
    List<Ticket>? tickets,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    int? page,
    int? total,
    Object? estadoFiltro = _unset,
    Object? placaFiltro = _unset,
    Object? desdeFiltro = _unset,
    Object? hastaFiltro = _unset,
  }) => TicketListState(
    tickets: tickets ?? this.tickets,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    page: page ?? this.page,
    total: total ?? this.total,
    estadoFiltro: identical(estadoFiltro, _unset) ? this.estadoFiltro : estadoFiltro as EstadoTicket?,
    placaFiltro: identical(placaFiltro, _unset) ? this.placaFiltro : placaFiltro as String?,
    desdeFiltro: identical(desdeFiltro, _unset) ? this.desdeFiltro : desdeFiltro as DateTime?,
    hastaFiltro: identical(hastaFiltro, _unset) ? this.hastaFiltro : hastaFiltro as DateTime?,
  );
}
