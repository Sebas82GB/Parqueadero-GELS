String? requiredValidator(String? value) =>
    (value == null || value.trim().isEmpty) ? 'Obligatorio' : null;

String? requiredIntegerValidator(String? value) {
  final requiredError = requiredValidator(value);
  if (requiredError != null) return requiredError;
  return int.tryParse(value!.trim()) == null ? 'Debe ser un número entero' : null;
}

String? placaValidator(String? value) =>
    (value == null || value.trim().isEmpty) ? 'Ingresa la placa' : null;
