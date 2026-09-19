import 'dart:convert';

import 'package:dio/dio.dart';

import '../../l10n/l10n.dart';

/// Коды ошибок, которые приложение показывает по-своему, а не общим текстом.
///
/// Сервер присылает их в теле: `{"detail": {"code": …, "message": …}}`. Код
/// нужен там, где текста мало — например, отказ в вызове вне зоны обслуживания
/// заслуживает отдельного диалога, а не снекбара среди прочих ошибок сети.
class ApiErrorCodes {
  ApiErrorCodes._();

  /// SOS из города, где нет экипажей: вызов не создан.
  static const String outsideServiceArea = 'outside_service_area';

  /// В аккаунт вошли на другом устройстве — эта сессия закончилась. Приходит
  /// с 401, приложение по нему разлогинивается как обычно, но человеку можно
  /// объяснить причину, а не показывать «сессия истекла».
  static const String deviceSessionMoved = 'device_session_moved';

  /// Аккаунт уже слишком часто переносили на новые устройства. В detail —
  /// retry_after (секунды) и next_switch_at (когда перенос снова возможен).
  static const String deviceSwitchLimit = 'device_switch_limit';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  /// Машинный код из тела ответа, если сервер его прислал (см. [ApiErrorCodes]).
  final String? code;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.code,
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
    final serverCode = codeFromResponseData(response?.data);

    // Экрана здесь нет — язык берём из выбранного в приложении.
    final l10n = currentL10n;
    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = l10n.errorTimeout;
        break;
      case DioExceptionType.connectionError:
        message = l10n.errorConnection;
        break;
      case DioExceptionType.badResponse:
        // Ответ с машинным кодом сервер писал для человека: там и причина, и
        // что делать дальше. Общий текст по статусу («нет доступа к ресурсу»,
        // «слишком много запросов») такой ответ только обесценивает.
        if (serverCode != null && bodyMessage != null && bodyMessage.isNotEmpty) {
          message = bodyMessage;
        } else if (statusCode == 401) {
          message = l10n.errorSessionExpired;
        } else if (statusCode == 403) {
          message = l10n.errorForbidden;
        } else if (statusCode == 429) {
          message = l10n.errorTooManyRequests;
        } else if (bodyMessage != null && bodyMessage.isNotEmpty) {
          message = bodyMessage;
        } else {
          message = l10n.errorServer('$statusCode');
        }
        break;
      case DioExceptionType.cancel:
        message = l10n.errorCancelled;
        break;
      default:
        if (bodyMessage != null && bodyMessage.isNotEmpty) {
          message = bodyMessage;
        } else {
          message = l10n.errorUnknown;
        }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: response?.data,
      code: serverCode,
    );
  }

  /// Достаёт машинный код ошибки из тела ответа. Null, если сервер прислал
  /// обычную строковую ошибку — тогда у вызывающего есть только [message].
  static String? codeFromResponseData(dynamic data) {
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.startsWith('{')) {
        try {
          return codeFromResponseData(jsonDecode(trimmed));
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    if (data is Map) {
      final detail = data['detail'];
      if (detail is Map && detail['code'] is String) {
        return detail['code'] as String;
      }
      if (data['code'] is String) return data['code'] as String;
    }

    return null;
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
