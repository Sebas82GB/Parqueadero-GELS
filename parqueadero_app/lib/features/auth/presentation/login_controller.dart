import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import 'session_notifier.dart';

class LoginState {
  const LoginState({this.isLoading = false, this.error});

  final bool isLoading;
  /// Se guarda la excepción tipada (no solo el mensaje) para que la UI
  /// pueda distinguir [NetworkException] de [ApiException] sin volver a
  /// parsear nada.
  final AppException? error;
}

/// Estado propio de la pantalla de login (cargando/error), separado del
/// estado de sesión global para poder testear los tres estados de la
/// pantalla con el repositorio mockeado, sin tocar `SessionNotifier`.
class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> submit({required String email, required String password}) async {
    state = const LoginState(isLoading: true);
    try {
      await ref.read(sessionNotifierProvider.notifier).login(email: email, password: password);
      state = const LoginState();
    } on AppException catch (e) {
      state = LoginState(error: e);
    }
  }
}

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(LoginController.new);
