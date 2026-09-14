import '../../../../core/utils/money.dart';

/// Texto sin juicio de valor para una diferencia de caja: mismo tono para
/// sobrante, faltante o cuadre exacto, con el signo explícito. Se comparte
/// entre `ArqueoSummaryView`, el cálculo en vivo de `TurnoCierreScreen` y
/// `TurnoListItem` para que las tres usen exactamente la misma redacción.
String diferenciaTexto(int diferencia) {
  if (diferencia > 0) return 'Sobrante: +${formatMoney(diferencia)}';
  if (diferencia < 0) return 'Faltante: -${formatMoney(diferencia.abs())}';
  return 'Cuadre exacto: ${formatMoney(0)}';
}
