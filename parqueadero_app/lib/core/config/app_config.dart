import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuración leída de `--dart-define`. Nunca hardcodear la URL base.
class AppConfig {
  const AppConfig._(this.apiBaseUrl);

  final String apiBaseUrl;

  /// Lee `API_BASE_URL` del entorno de compilación. Falla de inmediato si no
  /// se definió, en vez de dejar que la app arranque con una URL vacía.
  factory AppConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (apiBaseUrl.isEmpty) {
      throw StateError(
        'Falta --dart-define=API_BASE_URL. Ejemplo:\n'
        'flutter run -d chrome --web-port=5173 '
        '--dart-define=API_BASE_URL=http://localhost:3000/api/v1',
      );
    }
    return AppConfig._(apiBaseUrl);
  }
}

/// Debe sobrescribirse en `main()` con [AppConfig.fromEnvironment]. El cuerpo
/// por defecto lanza a propósito: si algo lo lee sin la sobrescritura, es un
/// error de wiring que debe fallar ruidosamente, no devolver una config vacía.
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider no fue sobrescrito en main()');
});
