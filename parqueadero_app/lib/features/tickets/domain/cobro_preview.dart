import 'desglose_item.dart';

/// Resultado de `GET /tickets/:id/preview-cobro`: lo que cobraría la salida
/// si se registrara en este momento, sin cerrar el ticket ni modificar nada.
/// `valorTotal` es null únicamente cuando el vehículo es tipo OTRO y todavía
/// no hay un valor manual (ver [DesgloseManual.motivo]).
class CobroPreview {
  const CobroPreview({
    required this.valorTotal,
    required this.desglose,
    required this.horaEntrada,
    required this.horaSalida,
  });

  final int? valorTotal;
  final List<DesgloseItem> desglose;
  final DateTime horaEntrada;

  /// La hora a la que el backend calculó este preview (no la hora real de
  /// salida: el ticket sigue ABIERTO). Sirve para mostrarle al operador
  /// cuándo se calculó por última vez.
  final DateTime horaSalida;
}
