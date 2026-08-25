import 'package:flutter/services.dart';

/// Envoltorio fino sobre `HapticFeedback` (parte de `flutter/services.dart`,
/// sin paquete nuevo). En Chrome de escritorio no hace nada — la mayoría de
/// navegadores no exponen vibración — pero queda listo para cuando la app
/// corra en Android/iOS sin que haya que tocar el sitio de la llamada.
void tapFeedback() => HapticFeedback.selectionClick();
