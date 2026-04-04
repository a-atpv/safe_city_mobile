import 'package:dio/dio.dart';
import 'api_client.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  
  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });
  
  factory ApiException.fromDioError(DioException error) {
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
        final data = error.response?.data;
        final statusCode = error.response?.statusCode;
        
        if (statusCode == 401) {
          message = 'Сессия истекла. Пожалуйста, войдите снова.';
        } else if (statusCode == 403) {
          message = 'У вас нет доступа к этому ресурсу.';
        } else if (statusCode == 429) {
          message = 'Слишком много запросов. Попробуйте позже.';
        } else if (data is Map && data.containsKey('detail')) {
          message = data['detail'].toString();
        } else if (data is Map && data.containsKey('message')) {
          message = data['message'].toString();
        } else {
          message = 'Ошибка сервера: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Запрос отменён';
        break;
      default:
        message = 'Произошла неизвестная ошибка';
    }
    
    return ApiException(
      message: message,
      statusCode: error.response?.statusCode,
      data: error.response?.data,
    );
  }

  String get shortMessage {
    if (message.length <= 60) return message;
    // Simple logic to truncate and add ellipsis for "short" version
    return '${message.substring(0, 57)}...';
  }
  
  @override
  String toString() => message;
}

mixin ApiMixin {
  ApiClient get apiClient => ApiClient();
  
  Future<T> safeApiCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
