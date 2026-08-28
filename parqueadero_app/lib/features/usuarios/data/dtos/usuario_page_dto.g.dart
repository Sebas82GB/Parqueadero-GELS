// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario_page_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsuarioPageMetaDto _$UsuarioPageMetaDtoFromJson(Map<String, dynamic> json) =>
    UsuarioPageMetaDto(
      page: (json['page'] as num).toInt(),
      perPage: (json['perPage'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

UsuarioPageDto _$UsuarioPageDtoFromJson(Map<String, dynamic> json) =>
    UsuarioPageDto(
      data: (json['data'] as List<dynamic>)
          .map((e) => UsuarioDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: UsuarioPageMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
    );
