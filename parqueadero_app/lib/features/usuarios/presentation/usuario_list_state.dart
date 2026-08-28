import '../../auth/domain/usuario.dart';

const Object _unset = Object();

class UsuarioListState {
  const UsuarioListState({
    this.usuarios = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.page = 1,
    this.total = 0,
    this.rolFiltro,
    this.activoFiltro,
  });

  final List<Usuario> usuarios;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int page;
  final int total;
  final RolUsuario? rolFiltro;
  final bool? activoFiltro;

  bool get hayMas => usuarios.length < total;

  UsuarioListState copyWith({
    List<Usuario>? usuarios,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    int? page,
    int? total,
    Object? rolFiltro = _unset,
    Object? activoFiltro = _unset,
  }) => UsuarioListState(
    usuarios: usuarios ?? this.usuarios,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    page: page ?? this.page,
    total: total ?? this.total,
    rolFiltro: identical(rolFiltro, _unset) ? this.rolFiltro : rolFiltro as RolUsuario?,
    activoFiltro: identical(activoFiltro, _unset) ? this.activoFiltro : activoFiltro as bool?,
  );
}
