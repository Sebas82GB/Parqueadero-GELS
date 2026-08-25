import 'package:json_annotation/json_annotation.dart';

import 'usuario_dto.dart';

part 'login_response_dto.g.dart';

@JsonSerializable(createToJson: false)
class LoginResponseDto {
  LoginResponseDto({required this.usuario, required this.accessToken, required this.refreshToken});

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) => _$LoginResponseDtoFromJson(json);

  final UsuarioDto usuario;
  final String accessToken;
  final String refreshToken;
}
