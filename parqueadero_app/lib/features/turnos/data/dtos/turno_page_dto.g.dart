// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turno_page_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TurnoPageMetaDto _$TurnoPageMetaDtoFromJson(Map<String, dynamic> json) =>
    TurnoPageMetaDto(
      page: (json['page'] as num).toInt(),
      perPage: (json['perPage'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

TurnoPageDto _$TurnoPageDtoFromJson(Map<String, dynamic> json) => TurnoPageDto(
  data: (json['data'] as List<dynamic>)
      .map((e) => TurnoDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: TurnoPageMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
);
