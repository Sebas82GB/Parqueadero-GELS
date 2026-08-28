import 'package:json_annotation/json_annotation.dart';

import '../../domain/usuario.dart';

part 'usuario_dto.g.dart';

/// Nunca se re-serializa hacia el backend, por eso no genera `toJson`.
@JsonSerializable(createToJson: false)
class UsuarioDto {
  UsuarioDto({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activo,
    this.baseInicialTurno,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UsuarioDto.fromJson(Map<String, dynamic> json) => _$UsuarioDtoFromJson(json);

  final String id;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;
  final int? baseInicialTurno;
  final String createdAt;
  final String updatedAt;

  Usuario toDomain() => Usuario(
    id: id,
    nombre: nombre,
    email: email,
    rol: RolUsuario.fromBackend(rol),
    activo: activo,
    baseInicialTurno: baseInicialTurno,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );
}
