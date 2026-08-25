import '../domain/horario.dart';

class HorarioListState {
  const HorarioListState({this.horarios = const [], this.isLoading = false, this.errorMessage});

  /// Lista COMPLETA de horarios (vigente e histórico), sin filtrar.
  final List<Horario> horarios;
  final bool isLoading;
  final String? errorMessage;

  HorarioListState copyWith({List<Horario>? horarios, bool? isLoading, String? errorMessage, bool clearError = false}) =>
      HorarioListState(
        horarios: horarios ?? this.horarios,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  /// El horario vigente ahora mismo, si lo hay. Solo puede haber uno (sin
  /// discriminador, a diferencia de Tarifa).
  Horario? get vigente {
    for (final h in horarios) {
      if (h.esVigente()) return h;
    }
    return null;
  }

  /// El resto (todo lo que no es el vigente), ordenado por `vigenteDesde`
  /// descendente: el más reciente primero.
  List<Horario> get historico {
    final actual = vigente;
    final resto = [for (final h in horarios) if (h.id != actual?.id) h];
    resto.sort((a, b) => b.vigenteDesde.compareTo(a.vigenteDesde));
    return resto;
  }
}
