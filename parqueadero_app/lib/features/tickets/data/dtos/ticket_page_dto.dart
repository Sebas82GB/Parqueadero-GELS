import 'package:json_annotation/json_annotation.dart';

import 'ticket_dto.dart';

part 'ticket_page_dto.g.dart';

/// Parseo de `{ data: [...], meta: { page, perPage, total } }`. Interno a
/// `data/`: nunca se expone fuera de `ticket_repository_impl.dart`.
@JsonSerializable(createToJson: false)
class TicketPageMetaDto {
  TicketPageMetaDto({required this.page, required this.perPage, required this.total});

  factory TicketPageMetaDto.fromJson(Map<String, dynamic> json) => _$TicketPageMetaDtoFromJson(json);

  final int page;
  final int perPage;
  final int total;
}

@JsonSerializable(createToJson: false)
class TicketPageDto {
  TicketPageDto({required this.data, required this.meta});

  factory TicketPageDto.fromJson(Map<String, dynamic> json) => _$TicketPageDtoFromJson(json);

  final List<TicketDto> data;
  final TicketPageMetaDto meta;
}
