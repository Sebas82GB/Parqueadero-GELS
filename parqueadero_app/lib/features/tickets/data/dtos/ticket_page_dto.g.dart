// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_page_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketPageMetaDto _$TicketPageMetaDtoFromJson(Map<String, dynamic> json) =>
    TicketPageMetaDto(
      page: (json['page'] as num).toInt(),
      perPage: (json['perPage'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

TicketPageDto _$TicketPageDtoFromJson(Map<String, dynamic> json) =>
    TicketPageDto(
      data: (json['data'] as List<dynamic>)
          .map((e) => TicketDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: TicketPageMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
    );
