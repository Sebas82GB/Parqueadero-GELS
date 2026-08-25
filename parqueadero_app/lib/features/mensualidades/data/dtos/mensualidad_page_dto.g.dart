// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mensualidad_page_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MensualidadPageMetaDto _$MensualidadPageMetaDtoFromJson(
  Map<String, dynamic> json,
) => MensualidadPageMetaDto(
  page: (json['page'] as num).toInt(),
  perPage: (json['perPage'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);

MensualidadPageDto _$MensualidadPageDtoFromJson(Map<String, dynamic> json) =>
    MensualidadPageDto(
      data: (json['data'] as List<dynamic>)
          .map((e) => MensualidadDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MensualidadPageMetaDto.fromJson(
        json['meta'] as Map<String, dynamic>,
      ),
    );
