import 'package:intl/intl.dart';

/// Colombia no observa horario de verano: desplazamiento fijo UTC-5, todo el
/// año. Las fechas del backend llegan en UTC (regla 6 de CLAUDE.md); esta es
/// la única función que las convierte para mostrarlas.
DateTime toBogota(DateTime utc) => utc.toUtc().subtract(const Duration(hours: 5));

/// Requiere `initializeDateFormatting('es_CO')` llamado antes (ver `main.dart`).
String formatBogota(DateTime utc, [String pattern = 'd MMM y, h:mm a']) =>
    DateFormat(pattern, 'es_CO').format(toBogota(utc));
