import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Necesario antes de cualquier DateFormat con locale 'es_CO' (ver
  // core/utils/bogota_time.dart).
  await initializeDateFormatting('es_CO');

  // Falla antes de runApp si falta --dart-define=API_BASE_URL, no con un
  // null en tiempo de ejecución.
  final appConfig = AppConfig.fromEnvironment();

  runApp(
    ProviderScope(overrides: [appConfigProvider.overrideWithValue(appConfig)], child: const ParqueaderoApp()),
  );
}

class ParqueaderoApp extends ConsumerWidget {
  const ParqueaderoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Parqueadero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
