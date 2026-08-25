import 'package:json_annotation/json_annotation.dart';

import 'celda_dto.dart';

part 'celda_page_dto.g.dart';

/// Parseo de `{ data: [...], meta: { page, perPage, total } }`. Interno a
/// `data/`: nunca se expone fuera de `celda_repository_impl.dart`.
@JsonSerializable(createToJson: false)
class CeldaPageMetaDto {
  CeldaPageMetaDto({required this.page, required this.perPage, required this.total});

  factory CeldaPageMetaDto.fromJson(Map<String, dynamic> json) => _$CeldaPageMetaDtoFromJson(json);

  final int page;
  final int perPage;
  final int total;
}

@JsonSerializable(createToJson: false)
class CeldaPageDto {
  CeldaPageDto({required this.data, required this.meta});

  factory CeldaPageDto.fromJson(Map<String, dynamic> json) => _$CeldaPageDtoFromJson(json);

  final List<CeldaDto> data;
  final CeldaPageMetaDto meta;
}
