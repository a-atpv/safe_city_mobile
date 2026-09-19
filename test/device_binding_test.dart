import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_city/core/api/api_client.dart';
import 'package:safe_city/core/api/api_exception.dart';
import 'package:safe_city/core/api/device_identity.dart';

/// Аккаунт закреплён за одним устройством: сервер узнаёт телефон по заголовку
/// `X-Device-Id`. Что здесь проверяется:
///
/// * заголовок уходит вообще со всеми запросами, включая обновление токена —
///   у него отдельный Dio без интерцепторов, и про него легко забыть;
/// * идентификатор постоянный: если бы он менялся между запусками, каждый
///   старт приложения выглядел бы для сервера сменой телефона и выедал лимит
///   переносов;
/// * отказы про устройство человек видит словами сервера, а не общим текстом
///   вроде «нет доступа к этому ресурсу».
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

DioException _error(int status, Map<String, dynamic> body) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: body,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient client;
  late List<void> logouts;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'access',
      'refresh_token': 'refresh',
    });
    DeviceIdentity().resetCache();
    logouts = [];
    client = ApiClient();
    client.onLogout = () => logouts.add(null);
    client.takeSessionEndReason();
  });

  group('идентификатор устройства', () {
    test('уходит с каждым запросом', () async {
      RequestOptions? seen;
      client.dio.httpClientAdapter = _FakeAdapter((options) async {
        seen = options;
        return _json({'ok': true}, 200);
      });

      await client.dio.get('/user/me');

      expect(seen!.headers[DeviceIdentity.deviceIdHeader], isNotNull);
      expect(
        seen!.headers[DeviceIdentity.deviceIdHeader],
        matches(RegExp(r'^[0-9a-f]{32}$')),
        reason: 'сервер принимает только [A-Za-z0-9_.:-]{8,64}',
      );
    });

    test('не меняется между запусками приложения', () async {
      final seen = <String>[];
      client.dio.httpClientAdapter = _FakeAdapter((options) async {
        seen.add(options.headers[DeviceIdentity.deviceIdHeader] as String);
        return _json({'ok': true}, 200);
      });

      await client.dio.get('/user/me');
      // Новый запуск: кэш в памяти пуст, идентификатор должен прийти из
      // хранилища, а не родиться заново.
      DeviceIdentity().resetCache();
      await client.dio.get('/user/me');

      expect(seen, hasLength(2));
      expect(seen[0], seen[1]);
    });

    test('обновление токена тоже представляется устройством', () async {
      client.dio.httpClientAdapter =
          _FakeAdapter((_) async => _json({'detail': 'Invalid or expired token'}, 401));
      RequestOptions? refreshSeen;
      client.refreshHttpAdapter = _FakeAdapter((options) async {
        refreshSeen = options;
        return _json({'access_token': 'new-access', 'refresh_token': 'new-refresh'}, 200);
      });

      try {
        await client.dio.get('/user/me');
      } catch (_) {
        // Повтор запроса снова упрётся в 401 — здесь важен только refresh.
      }

      expect(refreshSeen, isNotNull, reason: 'ручка обновления должна быть вызвана');
      expect(refreshSeen!.headers[DeviceIdentity.deviceIdHeader], isNotNull);
    });
  });

  group('ошибки про устройство', () {
    test('вход на другом устройстве объясняется словами сервера', () {
      final error = ApiException.fromDioError(_error(401, {
        'detail': {
          'code': 'device_session_moved',
          'message': 'Вы вошли в аккаунт на другом устройстве',
        }
      }));

      expect(error.code, ApiErrorCodes.deviceSessionMoved);
      expect(error.message, 'Вы вошли в аккаунт на другом устройстве');
    });

    test('исчерпанный лимит переносов показывает дату, а не «слишком много запросов»', () {
      final error = ApiException.fromDioError(_error(429, {
        'detail': {
          'code': 'device_switch_limit',
          'message': 'Следующий перенос будет доступен 09.10.2026',
          'retry_after': 3600,
          'next_switch_at': '2026-10-09T06:00:00+00:00',
        }
      }));

      expect(error.code, ApiErrorCodes.deviceSwitchLimit);
      expect(error.message, contains('09.10.2026'));
    });

    test('оборванная сервером сессия оставляет причину для экрана входа', () async {
      final moved = {
        'detail': {
          'code': 'device_session_moved',
          'message': 'Вы вошли в аккаунт на другом устройстве',
        }
      };
      client.dio.httpClientAdapter = _FakeAdapter((_) async => _json(moved, 401));
      client.refreshHttpAdapter = _FakeAdapter((_) async => _json(moved, 401));

      try {
        await client.dio.get('/user/me');
      } catch (_) {}

      expect(logouts, hasLength(1), reason: 'отказ самой ручки refresh завершает сессию');
      expect(client.takeSessionEndReason(), 'Вы вошли в аккаунт на другом устройстве');
      expect(client.takeSessionEndReason(), isNull, reason: 'причина одноразовая');
    });

    test('просто истёкший refresh причину не выдумывает', () async {
      client.dio.httpClientAdapter =
          _FakeAdapter((_) async => _json({'detail': 'Invalid or expired token'}, 401));
      client.refreshHttpAdapter =
          _FakeAdapter((_) async => _json({'detail': 'Invalid refresh token'}, 401));

      try {
        await client.dio.get('/user/me');
      } catch (_) {}

      expect(logouts, hasLength(1));
      expect(client.takeSessionEndReason(), isNull);
    });

    test('403 без машинного кода остаётся общим текстом', () {
      final error = ApiException.fromDioError(_error(403, {'detail': 'Active subscription required'}));

      expect(error.code, isNull);
      expect(error.message, 'У вас нет доступа к этому ресурсу.');
    });
  });
}
