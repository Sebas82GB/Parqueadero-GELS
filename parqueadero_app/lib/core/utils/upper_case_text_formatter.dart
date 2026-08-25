import 'package:flutter/services.dart';

/// La placa siempre viaja en mayúsculas hacia el backend; esto la muestra
/// así ya mientras el operador escribe, para feedback visual inmediato (el
/// backend igual normaliza, esto no reemplaza esa validación).
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}
