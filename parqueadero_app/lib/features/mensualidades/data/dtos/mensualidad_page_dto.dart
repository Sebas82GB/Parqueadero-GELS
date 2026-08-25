import 'package:json_annotation/json_annotation.dart';

import 'mensualidad_dto.dart';

part 'mensualidad_page_dto.g.dart';

/// Parseo de `{ data: [...], meta: { page, perPage, total } }`. Interno a
/// `data/`: nunca se expone fuera de `mensualidad_repository_impl.dart`.
@JsonSerializable(createToJson: false)
class MensualidadPageMetaDto {
  MensualidadPageMetaDto({required this.page, required this.perPage, required this.total});

  factory MensualidadPageMetaDto.fromJson(Map<String, dynamic> json) =>
      _$MensualidadPageMetaDtoFromJson(json);

  final int page;
  final int perPage;
  final int total;
}

@JsonSerializable(createToJson: false)
class MensualidadPageDto {
  MensualidadPageDto({required this.data, required this.meta});

  factory MensualidadPageDto.fromJson(Map<String, dynamic> json) => _$MensualidadPageDtoFromJson(json);

  final List<MensualidadDto> data;
  final MensualidadPageMetaDto meta;
}
