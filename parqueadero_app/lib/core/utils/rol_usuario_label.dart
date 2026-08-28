import '../../features/auth/domain/usuario.dart';

String rolUsuarioLabel(RolUsuario rol) => switch (rol) {
  RolUsuario.admin => 'Administrador',
  RolUsuario.operador => 'Operador',
};
