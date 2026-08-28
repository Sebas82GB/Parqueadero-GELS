import 'package:json_annotation/json_annotation.dart';

import '../../../auth/data/dtos/usuario_dto.dart';

part 'usuario_page_dto.g.dart';

@JsonSerializable(createToJson: false)
class UsuarioPageMetaDto {
  UsuarioPageMetaDto({required this.page, required this.perPage, required this.total});

  factory UsuarioPageMetaDto.fromJson(Map<String, dynamic> json) => _$UsuarioPageMetaDtoFromJson(json);

  final int page;
  final int perPage;
  final int total;
}

/// Reutiliza [UsuarioDto] (definido en `features/auth/data/dtos/`, no
/// duplicado acá): es exactamente la misma forma que ya parsea `/auth/me` y
/// `/auth/login`, esto solo le agrega el sobre de paginación de `GET /usuarios`.
@JsonSerializable(createToJson: false)
class UsuarioPageDto {
  UsuarioPageDto({required this.data, required this.meta});

  factory UsuarioPageDto.fromJson(Map<String, dynamic> json) => _$UsuarioPageDtoFromJson(json);

  final List<UsuarioDto> data;
  final UsuarioPageMetaDto meta;
}
