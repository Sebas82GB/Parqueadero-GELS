import 'package:json_annotation/json_annotation.dart';

import 'turno_dto.dart';

part 'turno_page_dto.g.dart';

/// Parseo de `{ data: [...], meta: { page, perPage, total } }`. Interno a
/// `data/`: nunca se expone fuera de `turno_repository_impl.dart`.
@JsonSerializable(createToJson: false)
class TurnoPageMetaDto {
  TurnoPageMetaDto({required this.page, required this.perPage, required this.total});

  factory TurnoPageMetaDto.fromJson(Map<String, dynamic> json) => _$TurnoPageMetaDtoFromJson(json);

  final int page;
  final int perPage;
  final int total;
}

@JsonSerializable(createToJson: false)
class TurnoPageDto {
  TurnoPageDto({required this.data, required this.meta});

  factory TurnoPageDto.fromJson(Map<String, dynamic> json) => _$TurnoPageDtoFromJson(json);

  final List<TurnoDto> data;
  final TurnoPageMetaDto meta;
}
