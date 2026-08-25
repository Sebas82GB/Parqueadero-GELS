import '../domain/arqueo_turno.dart';

class TurnoDetailState {
  const TurnoDetailState({this.isLoading = false, this.errorMessage, this.arqueo});

  final bool isLoading;
  final String? errorMessage;
  final ArqueoTurno? arqueo;
}
