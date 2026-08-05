import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_city/core/api/api_client.dart';

/// What a 401 must and must not cost a user.
///
/// The access token lives 30 minutes, so the renew path runs constantly. Losing
/// the session means an e-mail OTP round trip, and it must only happen when the
/// server actually rejects the refresh token — never because the phone was on a
/// bad connection at the wrong moment.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.onFetch);

  final Future<ResponseBody> Function(RequestOptions options) onFetch;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      onFetch(options);
}

ResponseBody _json(Map<String, dynamic> body, int status) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient client;
  late List<void> logouts;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'old-access',
      'refresh_token': 'old-refresh',
    });
    logouts = [];
    client = ApiClient();
    client.onLogout = () => logouts.add(null);
  });

  test('unreachable renew endpoint keeps the session', () async {
    client.dio.httpClientAdapter =
        _FakeAdapter((_) async => _json({'detail': 'Invalid or expired token'}, 401));
    client.refreshHttpAdapter = _FakeAdapter(
      (options) async => throw DioException.connectionError(
        requestOptions: options,
        reason: 'no coverage',
      ),
    );

    await expectLater(client.dio.get('/user/me'), throwsA(isA<DioException>()));

    expect(await client.getAccessToken(), 'old-access');
    expect(logouts, isEmpty);
  });

  test('renew endpoint answering 5xx keeps the session', () async {
    client.dio.httpClientAdapter =
        _FakeAdapter((_) async => _json({'detail': 'Invalid or expired token'}, 401));
    client.refreshHttpAdapter =
        _FakeAdapter((_) async => _json({'detail': 'Bad gateway'}, 502));

    await expectLater(client.dio.get('/user/me'), throwsA(isA<DioException>()));

    expect(await client.getAccessToken(), 'old-access');
    expect(logouts, isEmpty);
  });

  test('refresh token rejected by the server ends the session', () async {
    client.dio.httpClientAdapter =
        _FakeAdapter((_) async => _json({'detail': 'Invalid or expired token'}, 401));
    client.refreshHttpAdapter =
        _FakeAdapter((_) async => _json({'detail': 'Invalid refresh token'}, 401));

    await expectLater(client.dio.get('/user/me'), throwsA(isA<DioException>()));

    expect(await client.getAccessToken(), isNull);
    expect(logouts, hasLength(1));
  });

  test('a 401 is renewed and the request retried with the new token', () async {
    var mainCalls = 0;
    String? retryAuthHeader;
    client.dio.httpClientAdapter = _FakeAdapter((options) async {
      mainCalls++;
      if (mainCalls == 1) return _json({'detail': 'Invalid or expired token'}, 401);
      retryAuthHeader = options.headers['Authorization'] as String?;
      return _json({'ok': true}, 200);
    });
    client.refreshHttpAdapter = _FakeAdapter(
      (_) async => _json({
        'access_token': 'new-access',
        'refresh_token': 'new-refresh',
      }, 200),
    );

    final response = await client.dio.get('/user/me');

    expect(response.data['ok'], isTrue);
    expect(mainCalls, 2);
    expect(retryAuthHeader, 'Bearer new-access');
    expect(await client.getAccessToken(), 'new-access');
    expect(logouts, isEmpty);
  });

  test('a request is retried once, not endlessly', () async {
    var mainCalls = 0;
    client.dio.httpClientAdapter = _FakeAdapter((_) async {
      mainCalls++;
      return _json({'detail': 'Invalid or expired token'}, 401);
    });
    client.refreshHttpAdapter = _FakeAdapter(
      (_) async => _json({
        'access_token': 'new-access',
        'refresh_token': 'new-refresh',
      }, 200),
    );

    await expectLater(client.dio.get('/user/me'), throwsA(isA<DioException>()));

    expect(mainCalls, 2, reason: 'original request + exactly one retry');
  });

  test('parallel 401s share a single renew', () async {
    var refreshCalls = 0;
    client.dio.httpClientAdapter = _FakeAdapter((options) async {
      if (options.headers['Authorization'] == 'Bearer new-access') {
        return _json({'ok': true}, 200);
      }
      return _json({'detail': 'Invalid or expired token'}, 401);
    });
    client.refreshHttpAdapter = _FakeAdapter((_) async {
      refreshCalls++;
      return _json({
        'access_token': 'new-access',
        'refresh_token': 'new-refresh',
      }, 200);
    });

    final responses = await Future.wait([
      client.dio.get('/user/me'),
      client.dio.get('/emergency/active'),
      client.dio.get('/notifications'),
    ]);

    expect(responses.every((r) => r.statusCode == 200), isTrue);
    expect(refreshCalls, 1);
    expect(logouts, isEmpty);
  });

  test('403 that is not an auth failure never touches the session', () async {
    client.dio.httpClientAdapter =
        _FakeAdapter((_) async => _json({'detail': 'Active subscription required'}, 403));
    var refreshCalls = 0;
    client.refreshHttpAdapter = _FakeAdapter((_) async {
      refreshCalls++;
      return _json({'detail': 'should not be called'}, 401);
    });

    await expectLater(client.dio.get('/emergency/sos'), throwsA(isA<DioException>()));

    expect(refreshCalls, 0);
    expect(await client.getAccessToken(), 'old-access');
    expect(logouts, isEmpty);
  });
}
