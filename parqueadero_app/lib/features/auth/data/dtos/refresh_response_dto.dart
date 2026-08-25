import 'package:json_annotation/json_annotation.dart';

part 'refresh_response_dto.g.dart';

/// A diferencia de [LoginResponseDto], la respuesta de refresh no trae `usuario`.
@JsonSerializable(createToJson: false)
class RefreshResponseDto {
  RefreshResponseDto({required this.accessToken, required this.refreshToken});

  factory RefreshResponseDto.fromJson(Map<String, dynamic> json) => _$RefreshResponseDtoFromJson(json);

  final String accessToken;
  final String refreshToken;
}
