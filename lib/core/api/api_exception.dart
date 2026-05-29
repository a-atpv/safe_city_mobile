import 'dart:convert';

import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  /// Converts any thrown value (Dio, ApiException, etc.) into a user-facing [ApiException].
  factory ApiException.fromAny(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      if (error.error is ApiException) return error.error as ApiException;
      return ApiException.fromDioError(error);
    }
    return ApiException(message: error.toString());
  }

  factory ApiException.fromDioError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final bodyMessage = messageFromResponseData(response?.data);

    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Превышено время ожидания. Проверьте интернет-соединение.';
        break;
      case DioExceptionType.connectionError:
        message = 'Ошибка подключения. Проверьте интернет-соединение.';
        break;
      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          message = 'Сессия истекла. Пожалуйста, войдите снова.';
        } else if (statusCode == 403) {
          message = 'У вас нет доступа к этому ресурсу.';
        } else if (statusCode == 429) {
          message = 'Слишком много запросов. Попробуйте позже.';
        } else if (bodyMessage != null && bodyMessage.isNotEmpty) {
          message = bodyMessage;
        } else {
          message = 'Ошибка сервера: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Запрос отменён';
        break;
      default:
        if (bodyMessage != null && bodyMessage.isNotEmpty) {
          message = bodyMessage;
        } else {
          message = 'Произошла неизвестная ошибка';
        }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: response?.data,
    );
  }

  /// Extracts a human-readable message from an API error response body.
  static String? messageFromResponseData(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          return messageFromResponseData(jsonDecode(trimmed));
        } catch (_) {
          return trimmed;
        }
      }
      return trimmed;
    }

    if (data is Map) {
      for (final key in ['detail', 'message', 'error', 'errors']) {
        if (data.containsKey(key)) {
          final formatted = _formatDetail(data[key]);
          if (formatted.isNotEmpty) return formatted;
        }
      }
    }

    if (data is List) {
      final formatted = data.map(_formatDetail).where((s) => s.isNotEmpty).join('\n');
      return formatted.isEmpty ? null : formatted;
    }

    final text = data.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _formatDetail(dynamic detail) {
    if (detail == null) return '';
    if (detail is String) return detail;
    if (detail is List) {
      return detail.map(_formatDetail).where((s) => s.isNotEmpty).join('\n');
    }
    if (detail is Map) {
      final msg = detail['msg'] ?? detail['message'] ?? detail['detail'];
      if (msg != null) return _formatDetail(msg);
      return detail.toString();
    }
    return detail.toString();
  }

  String get shortMessage {
    if (message.length <= 60) return message;
    return '${message.substring(0, 57)}...';
  }

  @override
  String toString() => message;
}

mixin ApiMixin {
  Future<T> safeApiCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.fromAny(e);
    }
  }
}
