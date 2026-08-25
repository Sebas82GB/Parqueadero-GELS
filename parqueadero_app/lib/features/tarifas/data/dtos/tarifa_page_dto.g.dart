// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tarifa_page_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TarifaPageMetaDto _$TarifaPageMetaDtoFromJson(Map<String, dynamic> json) =>
    TarifaPageMetaDto(
      page: (json['page'] as num).toInt(),
      perPage: (json['perPage'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

TarifaPageDto _$TarifaPageDtoFromJson(Map<String, dynamic> json) =>
    TarifaPageDto(
      data: (json['data'] as List<dynamic>)
          .map((e) => TarifaDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: TarifaPageMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
    );
