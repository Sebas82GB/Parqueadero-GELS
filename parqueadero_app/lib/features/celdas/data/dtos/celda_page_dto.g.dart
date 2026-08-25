// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'celda_page_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CeldaPageMetaDto _$CeldaPageMetaDtoFromJson(Map<String, dynamic> json) =>
    CeldaPageMetaDto(
      page: (json['page'] as num).toInt(),
      perPage: (json['perPage'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

CeldaPageDto _$CeldaPageDtoFromJson(Map<String, dynamic> json) => CeldaPageDto(
  data: (json['data'] as List<dynamic>)
      .map((e) => CeldaDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: CeldaPageMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
);
