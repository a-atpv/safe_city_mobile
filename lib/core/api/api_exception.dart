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
        if (data is Map && data.containsKey('detail')) {
          message = data['detail'].toString();
        } else if (data is Map && data.containsKey('message')) {
          message = data['message'].toString();
        } else {
          message = 'Ошибка сервера: ${error.response?.statusCode}';
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
