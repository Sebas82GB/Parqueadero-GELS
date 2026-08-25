import '../../domain/cobro_preview.dart';
import 'desglose_item_dto.dart';

/// `GET /tickets/:id/preview-cobro`. Mismo motivo que `desglose_item_dto.dart`
/// para no usar `json_serializable` acá: `valorTotal` puede ser null
/// (vehículo OTRO) y `desglose` ya tiene su propio parser heterogéneo, que
/// se reutiliza tal cual.
CobroPreview cobroPreviewFromJson(Map<String, dynamic> json) => CobroPreview(
  valorTotal: json['valorTotal'] as int?,
  desglose: desgloseFromJson(json['desglose'] as List<dynamic>?),
  horaEntrada: DateTime.parse(json['horaEntrada'] as String),
  horaSalida: DateTime.parse(json['horaSalida'] as String),
);
