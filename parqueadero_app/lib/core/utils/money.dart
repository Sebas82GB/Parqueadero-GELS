import 'package:intl/intl.dart';

/// El backend manda enteros en pesos colombianos; esta es la única función
/// que los formatea para mostrarlos. Nunca se dividen ni se convierten a
/// `double` (regla 5 de CLAUDE.md).
String formatMoney(int pesos) =>
    NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0).format(pesos);
