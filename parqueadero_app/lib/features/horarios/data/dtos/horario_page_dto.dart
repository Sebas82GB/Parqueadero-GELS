import 'package:json_annotation/json_annotation.dart';

import 'horario_dto.dart';

part 'horario_page_dto.g.dart';

/// Parseo de `{ data: [...], meta: { page, perPage, total } }`. Interno a
/// `data/`: nunca se expone fuera de `horario_repository_impl.dart`.
@JsonSerializable(createToJson: false)
class HorarioPageMetaDto {
  HorarioPageMetaDto({required this.page, required this.perPage, required this.total});

  factory HorarioPageMetaDto.fromJson(Map<String, dynamic> json) =>
      _$HorarioPageMetaDtoFromJson(json);

  final int page;
  final int perPage;
  final int total;
}

@JsonSerializable(createToJson: false)
class HorarioPageDto {
  HorarioPageDto({required this.data, required this.meta});

  factory HorarioPageDto.fromJson(Map<String, dynamic> json) => _$HorarioPageDtoFromJson(json);

  final List<HorarioDto> data;
  final HorarioPageMetaDto meta;
}
