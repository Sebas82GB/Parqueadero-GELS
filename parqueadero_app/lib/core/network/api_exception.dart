import 'package:dio/dio.dart';

/// Marcador común: ambas excepciones exponen `.message`, listo para mostrar
/// verbatim en la UI (nunca reescrito).
sealed class AppException implements Exception {
  String get message;

  factory AppException.fromDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      return ApiException.fromResponse(e.response!, data['error'] as Map<String, dynamic>);
    }
    return NetworkException.fromType(e.type);
  }
}

class ApiErrorDetail {
  const ApiErrorDetail({required this.field, required this.message});

  factory ApiErrorDetail.fromJson(Map<String, dynamic> json) =>
      ApiErrorDetail(field: json['field'] as String? ?? '', message: json['message'] as String? ?? '');

  final String field;
  final String message;
}

/// Error devuelto por el backend con la forma `{error:{code,message,details}}`.
class ApiException implements AppException {
  const ApiException({required this.code, required this.message, required this.statusCode, this.details = const []});

  factory ApiException.fromResponse(Response response, Map<String, dynamic> error) {
    final rawDetails = error['details'];
    return ApiException(
      code: error['code'] as String? ?? 'UNKNOWN',
      message: error['message'] as String? ?? 'Ha ocurrido un error inesperado',
      statusCode: response.statusCode ?? 0,
      details: rawDetails is List
          ? rawDetails.whereType<Map<String, dynamic>>().map(ApiErrorDetail.fromJson).toList()
          : const [],
    );
  }

  final String code;
  @override
  final String message;
  final int statusCode;
  final List<ApiErrorDetail> details;
}

/// Sin respuesta del backend: timeout, sin conexión, error desconocido de
/// dio. El mensaje es genérico y en español, provisto por la app porque el
/// backend nunca llegó a responder.
class NetworkException implements AppException {
  const NetworkException({required this.message, required this.type});

  factory NetworkException.fromType(DioExceptionType type) => NetworkException(
    message: switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'El servidor tardó demasiado en responder. Intenta de nuevo.',
      DioExceptionType.connectionError => 'No hay conexión con el servidor.',
      _ => 'Ha ocurrido un error inesperado. Intenta de nuevo.',
    },
    type: type,
  );

  @override
  final String message;
  final DioExceptionType type;
}
