import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Callback to trigger logout in the UI/Provider
  void Function()? onLogout;
  
  // To handle concurrent token refresh
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;
  
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
          // If we are already refreshing, wait for it to finish
          if (_isRefreshing) {
            final refreshed = await _refreshCompleter?.future ?? false;
            if (refreshed) {
              // Retry the request
              return _retry(error.requestOptions, handler);
            }
          } else {
            // Start token refresh
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request
              return _retry(error.requestOptions, handler);
            } else {
              // Refresh failed, trigger logout
              await clearTokens();
              onLogout?.call();
            }
          }
        }
        return handler.next(error);
      },
    ));
  }
  
  Dio get dio => _dio;
  
  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }
    
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();
    
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) {
        _isRefreshing = false;
        _refreshCompleter?.complete(false);
        return false;
      }
      
      final dio = Dio();
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
        _isRefreshing = false;
        _refreshCompleter?.complete(true);
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
    
    _isRefreshing = false;
    _refreshCompleter?.complete(false);
    return false;
  }

  Future<void> _retry(RequestOptions requestOptions, ErrorInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    requestOptions.headers['Authorization'] = 'Bearer $token';
    final response = await _dio.fetch(requestOptions);
    return handler.resolve(response);
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

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }
}
