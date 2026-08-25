// `triggerBrowserPrint()`: dispara el diálogo de impresión nativo del
// navegador. Import condicional (patrón estándar de Dart, sin paquete
// nuevo) para que `dart:html` nunca se compile en una plataforma que no sea
// web — plataforma actual de desarrollo, pero Android/iOS vendrán después y
// ninguna decisión de hoy debe cerrarles la puerta (regla del CLAUDE.md de
// este proyecto).
export 'print_launcher_stub.dart' if (dart.library.html) 'print_launcher_web.dart';
