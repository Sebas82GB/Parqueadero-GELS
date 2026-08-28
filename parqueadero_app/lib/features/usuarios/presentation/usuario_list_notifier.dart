import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/domain/usuario.dart';
import '../data/usuario_repository_impl.dart';
import 'usuario_list_state.dart';

const _perPage = 20;

/// Historial paginado con filtros, mismo espíritu que `TurnoListNotifier`.
class UsuarioListNotifier extends Notifier<UsuarioListState> {
  bool _isLoading = false;

  @override
  UsuarioListState build() {
    Future.microtask(() => cargar(reset: true));
    return const UsuarioListState(isLoading: true);
  }

  Future<void> cargar({bool reset = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    if (reset) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final pagina = await ref
          .read(usuarioRepositoryProvider)
          .listar(rol: state.rolFiltro, activo: state.activoFiltro, page: 1, perPage: _perPage);
      if (!ref.mounted) return;
      state = state.copyWith(
        usuarios: pagina.data,
        isLoading: false,
        page: pagina.page,
        total: pagina.total,
        clearError: true,
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> cargarMas() async {
    if (_isLoading || !state.hayMas) return;
    _isLoading = true;
    state = state.copyWith(isLoadingMore: true);
    try {
      final pagina = await ref
          .read(usuarioRepositoryProvider)
          .listar(
            rol: state.rolFiltro,
            activo: state.activoFiltro,
            page: state.page + 1,
            perPage: _perPage,
          );
      if (!ref.mounted) return;
      state = state.copyWith(
        usuarios: [...state.usuarios, ...pagina.data],
        isLoadingMore: false,
        page: pagina.page,
        total: pagina.total,
      );
    } on AppException catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoadingMore: false);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refrescar() => cargar(reset: true);

  void setRolFiltro(RolUsuario? rol) {
    state = state.copyWith(rolFiltro: rol);
    cargar(reset: true);
  }

  void setActivoFiltro(bool? activo) {
    state = state.copyWith(activoFiltro: activo);
    cargar(reset: true);
  }

  void limpiarFiltros() {
    state = state.copyWith(rolFiltro: null, activoFiltro: null);
    cargar(reset: true);
  }

  /// Reemplaza en el listado ya cargado el usuario que acaba de editarse o
  /// crearse, para no tener que volver a pedir toda la página — mismo
  /// patrón que `MensualidadListNotifier.reemplazarMensualidad`.
  void reemplazarUsuario(Usuario actualizado) {
    state = state.copyWith(
      usuarios: [
        for (final u in state.usuarios) if (u.id == actualizado.id) actualizado else u,
      ],
    );
  }

  void agregarUsuario(Usuario nuevo) {
    state = state.copyWith(usuarios: [nuevo, ...state.usuarios], total: state.total + 1);
  }
}

final usuarioListNotifierProvider =
    NotifierProvider.autoDispose<UsuarioListNotifier, UsuarioListState>(UsuarioListNotifier.new);
