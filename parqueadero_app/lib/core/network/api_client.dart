import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/token_storage.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';
import 'refresh_interceptor.dart';
import 'session_events.dart';

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final sessionEvents = ref.watch(sessionEventsProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // El RefreshInterceptor se referencia a sí mismo (mismo `dio`) para
  // reintentar la petición original; es seguro porque solo se usa cuando ya
  // corre una petición posterior, momento en que `dio` ya está completamente
  // asignado.
  dio.interceptors.addAll([
    AuthInterceptor(tokenStorage),
    RefreshInterceptor(dio: dio, tokenStorage: tokenStorage, sessionEvents: sessionEvents),
  ]);

  return dio;
});
