import '../domain/ticket.dart';

class TicketDetailState {
  const TicketDetailState({this.isLoading = false, this.errorMessage, this.ticket});

  final bool isLoading;
  final String? errorMessage;
  final Ticket? ticket;
}
