import 'package:json_annotation/json_annotation.dart';

import 'tarifa_dto.dart';

part 'tarifa_page_dto.g.dart';

/// Parseo de `{ data: [...], meta: { page, perPage, total } }`. Interno a
/// `data/`: nunca se expone fuera de `tarifa_repository_impl.dart`.
@JsonSerializable(createToJson: false)
class TarifaPageMetaDto {
  TarifaPageMetaDto({required this.page, required this.perPage, required this.total});

  factory TarifaPageMetaDto.fromJson(Map<String, dynamic> json) => _$TarifaPageMetaDtoFromJson(json);

  final int page;
  final int perPage;
  final int total;
}

@JsonSerializable(createToJson: false)
class TarifaPageDto {
  TarifaPageDto({required this.data, required this.meta});

  factory TarifaPageDto.fromJson(Map<String, dynamic> json) => _$TarifaPageDtoFromJson(json);

  final List<TarifaDto> data;
  final TarifaPageMetaDto meta;
}
