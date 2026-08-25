import '../domain/turno.dart';

class TurnoActivoState {
  const TurnoActivoState({this.isLoading = false, this.errorMessage, this.turno});

  final bool isLoading;
  final String? errorMessage;

  /// `null` significa "sin turno abierto" solo cuando `!isLoading` y
  /// `errorMessage == null` — mientras carga o si falló la consulta, `null`
  /// no debe leerse como una respuesta confirmada.
  final Turno? turno;
}
