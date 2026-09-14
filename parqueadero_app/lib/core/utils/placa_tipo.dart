import '../domain/tipo_vehiculo.dart';

/// Detección de [TipoVehiculo] a partir del **formato de placa
/// colombiana**, no una regla de negocio del backend: `POST /tickets`
/// acepta cualquier placa de 3 a 10 caracteres `[A-Za-z0-9-]`
/// (`ticket.validator.js`), sea cual sea el tipo de vehículo que se envíe.
/// Esto es solo una ayuda de captura para que el operador no tenga que
/// elegir el tipo a mano cuando la placa ya lo dice; la fuente de verdad
/// del cobro y de las reglas de vehículo sigue siendo el backend.
///
/// Formatos vigentes en Colombia:
/// - Carro: 3 letras + 3 números → `ABC123`.
/// - Moto (formato actual): 3 letras + 2 números + 1 letra → `ABC12D`.
/// - Moto (formato antiguo, sigue circulando): 3 letras + 2 números →
///   `ABC12`.
///
/// Cualquier otra combinación (bicicletas, formatos no colombianos, placas
/// mal escritas) no se autodetecta y devuelve `null`: le toca al operador
/// elegir el tipo a mano, por ejemplo "Otro".
final _placaCarroRegex = RegExp(r'^[A-Z]{3}[0-9]{3}$');
final _placaMotoActualRegex = RegExp(r'^[A-Z]{3}[0-9]{2}[A-Z]$');
final _placaMotoAntiguaRegex = RegExp(r'^[A-Z]{3}[0-9]{2}$');

/// Recibe [placa] ya normalizada (trim + mayúsculas, como la deja
/// `UpperCaseTextFormatter` en los campos de placa). Devuelve el
/// [TipoVehiculo] detectado o `null` si no coincide con ningún formato.
TipoVehiculo? tipoVehiculoDePlaca(String placa) {
  if (_placaCarroRegex.hasMatch(placa)) return TipoVehiculo.carro;
  if (_placaMotoActualRegex.hasMatch(placa)) return TipoVehiculo.moto;
  if (_placaMotoAntiguaRegex.hasMatch(placa)) return TipoVehiculo.moto;
  return null;
}
