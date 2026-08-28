import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/domain/usuario.dart';
import '../data/usuario_repository_impl.dart';
import 'usuario_detail_state.dart';
import 'usuario_list_notifier.dart';

/// Un estado por usuario abierto en detalle (`autoDispose.family<String>` por
/// `id`), mismo patrón que `MensualidadAccionNotifier`. El usuario que se
/// edita sale de `usuarioListNotifierProvider` (ya cargado en el listado);
/// este notifier solo expone la acción de guardar cambios.
class UsuarioDetailNotifier extends Notifier<UsuarioDetailState> {
  UsuarioDetailNotifier(this.usuarioId);

  final String usuarioId;

  @override
  UsuarioDetailState build() => const UsuarioDetailState();

  Future<bool> guardar({
    required String nombre,
    required String email,
    String? password,
    required RolUsuario rol,
    required bool activo,
    int? baseInicialTurno,
  }) async {
    state = const UsuarioDetailState(isLoading: true);
    try {
      final actualizado = await ref
          .read(usuarioRepositoryProvider)
          .actualizar(
            usuarioId,
            nombre: nombre,
            email: email,
            password: password,
            rol: rol,
            activo: activo,
            baseInicialTurno: baseInicialTurno,
          );
      if (!ref.mounted) return false;
      ref.read(usuarioListNotifierProvider.notifier).reemplazarUsuario(actualizado);
      state = const UsuarioDetailState();
      return true;
    } on AppException catch (e) {
      if (!ref.mounted) return false;
      state = UsuarioDetailState(errorMessage: e.message);
      return false;
    }
  }
}

final usuarioDetailNotifierProvider = NotifierProvider.autoDispose
    .family<UsuarioDetailNotifier, UsuarioDetailState, String>(UsuarioDetailNotifier.new);
