/// Formatea una duración transcurrida para mostrarse al operador, p.ej.
/// "1h 30min" o "45min". Presentación pura: no decide nada, solo formatea.
String formatElapsed(Duration d) {
  final horas = d.inHours;
  final minutos = d.inMinutes.remainder(60);
  return horas > 0 ? '${horas}h ${minutos}min' : '${minutos}min';
}
