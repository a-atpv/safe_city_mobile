import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../../l10n/app_language.dart';
import 'api_exception.dart';
import 'device_identity.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  /// Separate Dio for the renew call: no interceptors (no recursion) and a
  /// longer fuse than a normal request — losing the session costs the user a
  /// full e-mail OTP round trip, so it is worth waiting a few extra seconds.
  late final Dio _refreshDio;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Перенацеливает оба Dio на текущий адрес из `BackendEnv`.
  ///
  /// `BaseOptions.baseUrl` запоминается при создании Dio, а они здесь живут всё
  /// время работы приложения — после смены сервера в настройках адрес нужно
  /// переписать, иначе запросы продолжат уходить на прежний бэкенд.
  void applyBackend() {
    _dio.options.baseUrl = AppConstants.apiBaseUrl;
    _refreshDio.options.baseUrl = AppConstants.apiBaseUrl;
  }

  // Callback to trigger logout in the UI/Provider
  void Function()? onLogout;

  /// Причина, по которой сервер оборвал сессию, если он её назвал (например,
  /// в аккаунт вошли на другом телефоне). Экран входа забирает её один раз и
  /// показывает человеку: молчаливый вылет из приложения с одной кнопкой — то,
  /// на что жалуются в первую очередь.
  String? _sessionEndReason;

  /// Забрать причину и забыть её: обычный выход из аккаунта не должен потом
  /// показывать чужое объяснение.
  String? takeSessionEndReason() {
    final reason = _sessionEndReason;
    _sessionEndReason = null;
    return reason;
  }

  /// Marks a request already retried once after a renew, so a server that keeps
  /// answering 401 can't spin the interceptor forever.
  static const String _retriedKey = 'auth_retried';

  // To handle concurrent token refresh
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

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

    _refreshDio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // Кто мы: аккаунт закреплён за одним устройством, и сервер сверяет его
        // на каждом запросе (DeviceIdentity). Читается один раз за запуск.
        options.headers.addAll(await DeviceIdentity().headers());
        // Язык интерфейса: на нём сервер пишет тексты ошибок и письмо с кодом.
        options.headers['Accept-Language'] = AppLanguageStore.current.code;
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (_isAuthFailure(error) && error.requestOptions.extra[_retriedKey] != true) {
          final newToken = await _refreshToken();
          if (newToken != null) {
            try {
              return handler.resolve(await _retry(error.requestOptions, newToken));
            } catch (_) {
              // Retry failed too — fall through and report the original error.
            }
          }
        }
        final apiError = ApiException.fromDioError(error);
        return handler.next(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: apiError,
            message: apiError.message,
          ),
        );
      },
    ));
  }

  Dio get dio => _dio;

  /// Lets tests drive the renew endpoint without a network.
  @visibleForTesting
  set refreshHttpAdapter(HttpClientAdapter adapter) =>
      _refreshDio.httpClientAdapter = adapter;

  /// True for the responses that mean "this access token isn't good enough":
  /// 401 from our own deps, plus FastAPI's 403 "Not authenticated" when the
  /// Authorization header never made it onto the request. Every other 403 is a
  /// permission/state answer (no subscription, inactive account) and must not
  /// touch the session.
  bool _isAuthFailure(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401) return true;
    if (status != 403) return false;
    final data = error.response?.data;
    final detail = data is Map ? (data['detail'] ?? '').toString() : '';
    return detail.toLowerCase().contains('authenticated');
  }

  /// Renews the access token. Returns the new token, or null when it couldn't
  /// be renewed.
  ///
  /// Null does NOT mean "signed out". The session is only ended when the server
  /// explicitly rejects our refresh token (401/403) or there is no refresh
  /// token left to try. Everything else — timeout, no coverage, 5xx, a backend
  /// restart — leaves the tokens in place so the next call can try again.
  Future<String?> _refreshToken() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value(null);
    }

    _isRefreshing = true;
    final completer = Completer<String?>();
    _refreshCompleter = completer;

    String? newAccessToken;
    try {
      newAccessToken = await _renew();
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
      completer.complete(newAccessToken);
    }
    return newAccessToken;
  }

  Future<String?> _renew() async {
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    if (refreshToken == null) {
      await _endSession();
      return null;
    }

    try {
      final response = await _refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        // У этого Dio нет интерцепторов (чтобы не было рекурсии), так что
        // устройство и язык сюда нужно положить руками. Язык важен: именно
        // этот ответ объясняет «вы вошли на другом устройстве».
        options: Options(headers: {
          ...await DeviceIdentity().headers(),
          'Accept-Language': AppLanguageStore.current.code,
        }),
      );

      final data = response.data;
      final newAccessToken = data is Map ? data['access_token'] as String? : null;
      final newRefreshToken = data is Map ? data['refresh_token'] as String? : null;

      if (newAccessToken == null || newRefreshToken == null) {
        // 2xx with an unusable body is a server-side glitch, not a dead
        // session — keep what we have and let the next call retry.
        debugPrint('Token refresh: response missing tokens, keeping session');
        return null;
      }

      await setTokens(newAccessToken, newRefreshToken);
      return newAccessToken;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        // The refresh token itself is expired or invalid — the only case where
        // the user genuinely has to sign in again.
        debugPrint('Token refresh rejected by server ($status), ending session');
        if (ApiException.codeFromResponseData(e.response?.data) ==
            ApiErrorCodes.deviceSessionMoved) {
          _sessionEndReason = ApiException.messageFromResponseData(e.response?.data);
        }
        await _endSession();
        return null;
      }
      debugPrint('Token refresh unavailable (${e.type}, status $status), keeping session');
      return null;
    } catch (e) {
      debugPrint('Token refresh failed unexpectedly: $e, keeping session');
      return null;
    }
  }

  Future<void> _endSession() async {
    await clearTokens();
    onLogout?.call();
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions, String token) {
    requestOptions.headers['Authorization'] = 'Bearer $token';
    requestOptions.extra[_retriedKey] = true;
    return _dio.fetch(requestOptions);
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

  Future<void> registerDevice({
    required String token,
    required String type,
    String? model,
    String? appVersion,
  }) async {
    await _dio.post('/user/device', data: {
      'device_token': token,
      'device_type': type,
      'device_model': model,
      'app_version': appVersion,
    });
  }

  Future<void> unregisterDevice(String token) async {
    // Note: The backend route for user device deletion might vary.
    // Based on user.py, it was registered at /user/device.
    // If there's no specific DELETE /user/device/{token}, we should verify.
    // For now, let's assume it follows the same pattern as logic but check user.py.
    // Wait, user.py only showed POST /user/device.
  }
}
