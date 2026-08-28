import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/domain/usuario.dart';
import '../data/usuario_repository_impl.dart';
import 'nuevo_usuario_state.dart';
import 'usuario_list_notifier.dart';

class NuevoUsuarioNotifier extends Notifier<NuevoUsuarioState> {
  @override
  NuevoUsuarioState build() => const NuevoUsuarioState();

  Future<Usuario?> crear({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    state = const NuevoUsuarioState(isLoading: true);
    try {
      final usuario = await ref
          .read(usuarioRepositoryProvider)
          .crear(nombre: nombre, email: email, password: password, rol: rol);
      if (!ref.mounted) return null;
      // El provider de la lista puede seguir vivo si la navegación a esta
      // pantalla fue un `push` (no se desechó) — mismo motivo que
      // `NuevaTarifaNotifier` junto a `tarifaListNotifierProvider`.
      ref.read(usuarioListNotifierProvider.notifier).agregarUsuario(usuario);
      state = const NuevoUsuarioState();
      return usuario;
    } on AppException catch (e) {
      if (!ref.mounted) return null;
      state = NuevoUsuarioState(errorMessage: e.message);
      return null;
    }
  }
}

final nuevoUsuarioNotifierProvider =
    NotifierProvider.autoDispose<NuevoUsuarioNotifier, NuevoUsuarioState>(NuevoUsuarioNotifier.new);
