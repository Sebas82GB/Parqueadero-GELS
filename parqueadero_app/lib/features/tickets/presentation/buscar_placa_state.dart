import '../domain/ticket.dart';

class BuscarPlacaState {
  const BuscarPlacaState({this.isLoading = false, this.errorMessage, this.buscado = false, this.ticket});

  final bool isLoading;
  final String? errorMessage;

  /// `true` una vez que una búsqueda respondió sin error — distingue
  /// "todavía no se buscó nada" de "se buscó y no hay registros para esa
  /// placa" (ambos tienen `ticket == null`).
  final bool buscado;

  /// El ticket más reciente para la placa buscada (abierto o cerrado), o
  /// `null` si no hay ningún registro. El backend siempre ordena por
  /// `horaEntrada` descendente, así que el primero de la página es el más
  /// reciente sin necesidad de pedir más de uno.
  final Ticket? ticket;
}
