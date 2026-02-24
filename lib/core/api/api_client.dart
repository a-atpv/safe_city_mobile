import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj), // Ensure it prints to console
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the request
            final token = await _storage.read(key: AppConstants.accessTokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        return handler.next(error);
      },
    ));
  }
  
  Dio get dio => _dio;
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;
      
      final dio = Dio();
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print(obj),
      ));
      final response = await dio.post(
        '${AppConstants.apiBaseUrl}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      
      if (response.statusCode == 200) {
        await _storage.write(
          key: AppConstants.accessTokenKey,
          value: response.data['access_token'],
        );
        await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: response.data['refresh_token'],
        );
        return true;
      }
    } catch (_) {}
    return false;
  }
  
  Future<void> setTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }
  
  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }
  
  Future<bool> hasValidToken() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }
}
