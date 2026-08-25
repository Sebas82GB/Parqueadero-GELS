// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'horario_page_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HorarioPageMetaDto _$HorarioPageMetaDtoFromJson(Map<String, dynamic> json) =>
    HorarioPageMetaDto(
      page: (json['page'] as num).toInt(),
      perPage: (json['perPage'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

HorarioPageDto _$HorarioPageDtoFromJson(Map<String, dynamic> json) =>
    HorarioPageDto(
      data: (json['data'] as List<dynamic>)
          .map((e) => HorarioDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: HorarioPageMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
    );
