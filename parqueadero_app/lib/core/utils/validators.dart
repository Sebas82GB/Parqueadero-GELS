import 'placa_tipo.dart';

String? requiredValidator(String? value) =>
    (value == null || value.trim().isEmpty) ? 'Obligatorio' : null;

String? requiredIntegerValidator(String? value) {
  final requiredError = requiredValidator(value);
  if (requiredError != null) return requiredError;
  return int.tryParse(value!.trim()) == null ? 'Debe ser un número entero' : null;
}

final _placaRegex = RegExp(r'^[A-Za-z0-9-]+$');

/// Espeja el contrato ya publicado del backend (`ticket.validator.js` /
/// `mensualidad.validator.js`: `min(3)`, `max(10)`,
/// `/^[A-Za-z0-9-]+$/`), no una regla de negocio nueva.
String? placaValidator(String? value) {
  final placa = value?.trim() ?? '';
  if (placa.isEmpty) return 'Ingresa la placa';
  if (placa.length < 3) return 'La placa debe tener al menos 3 caracteres';
  if (placa.length > 10) return 'La placa no puede superar 10 caracteres';
  if (!_placaRegex.hasMatch(placa)) return 'La placa solo admite letras, números y guiones';
  return null;
}

/// Igual que [placaValidator], pero además exige que la placa coincida con
/// un formato colombiano reconocible (`tipoVehiculoDePlaca`). Se usa solo
/// donde el tipo de vehículo se está detectando automáticamente de la
/// placa: si el operador ya eligió el tipo a mano (p. ej. "Otro" para una
/// bicicleta), [placaValidator] solo, sin este, es suficiente porque ahí la
/// placa puede ser cualquier cosa razonable.
String? placaConTipoValidator(String? value) {
  final formatoError = placaValidator(value);
  if (formatoError != null) return formatoError;
  final placa = value!.trim().toUpperCase();
  if (tipoVehiculoDePlaca(placa) == null) {
    return 'No reconocemos el formato. Un carro es ABC123 y una moto ABC12D. '
        'Si es otro vehículo, elige "Otro".';
  }
  return null;
}

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? emailValidator(String? value) {
  final requiredError = requiredValidator(value);
  if (requiredError != null) return requiredError;
  return _emailRegex.hasMatch(value!.trim()) ? null : 'Ingresa un email válido';
}
