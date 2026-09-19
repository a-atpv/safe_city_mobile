import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/app_constants.dart';

/// Чем приложение представляется серверу: постоянный идентификатор установки.
///
/// Аккаунт закреплён за одним устройством — вход с нового телефона переносит
/// привязку на него, а прежний разлогинивается. Узнаёт устройство сервер по
/// этому идентификатору в заголовке каждого запроса.
///
/// «Железного» номера у телефона нет: iOS отдаёт identifierForVendor, который
/// обнуляется вместе с последним приложением вендора, Android с прошлых версий
/// вообще ничего не отдаёт без привилегий. Поэтому идентификатор придумывает
/// сам клиент при первом запуске и держит в secure storage: на iOS это
/// Keychain, который переживает переустановку, на Android — хранилище, которое
/// стирается вместе с приложением, и после переустановки телефон придёт на
/// сервер новым. Сервер это терпит: у переносов привязки есть лимит, а не
/// запрет, и сброс через поддержку.
///
/// Отдельное правило на случай сбоя хранилища (на Android Keystore это
/// случается): молчим. Запрос без заголовка сервер обслуживает как раньше —
/// это хуже для привязки, но не оставляет человека без SOS из-за того, что
/// однажды не прочиталось хранилище. По той же причине идентификатор, который
/// не удалось записать, не используется: иначе каждый запуск приходил бы новым
/// устройством и выедал лимит переносов.
class DeviceIdentity {
  DeviceIdentity._internal();

  static final DeviceIdentity _instance = DeviceIdentity._internal();

  factory DeviceIdentity() => _instance;

  static const String deviceIdHeader = 'X-Device-Id';
  static const String platformHeader = 'X-Device-Platform';
  static const String appVersionHeader = 'X-App-Version';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Map<String, String>? _cached;

  /// Заголовки для запроса. Пустая карта — «представиться не вышло».
  Future<Map<String, String>> headers() async {
    final cached = _cached;
    if (cached != null) return cached;

    final id = await _deviceId();
    final headers = <String, String>{};
    if (id != null) {
      headers[deviceIdHeader] = id;
      final platform = _platform();
      if (platform != null) headers[platformHeader] = platform;
      final version = await _appVersion();
      if (version != null) headers[appVersionHeader] = version;
    }
    _cached = headers;
    return headers;
  }

  Future<String?> _deviceId() async {
    String? stored;
    try {
      stored = await _storage.read(key: AppConstants.deviceIdKey);
    } catch (e) {
      // Хранилище не открылось. Нового идентификатора не пишем: аккаунт
      // отвязывать от живого телефона из-за сбоя чтения нельзя.
      debugPrint('Device id read failed: $e');
      return null;
    }
    if (stored != null && stored.isNotEmpty) return stored;

    final generated = _generate();
    try {
      await _storage.write(key: AppConstants.deviceIdKey, value: generated);
    } catch (e) {
      debugPrint('Device id write failed: $e');
      return null;
    }
    return generated;
  }

  /// 32 шестнадцатеричных знака: столько же случайности, сколько у UUID v4, но
  /// без ещё одной зависимости, и подходит под то, что принимает сервер.
  String _generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String? _platform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return null; // тесты и десктоп — серверу такое знать незачем
  }

  Future<String?> _appVersion() async {
    try {
      return (await PackageInfo.fromPlatform()).version;
    } catch (e) {
      debugPrint('App version unavailable: $e');
      return null;
    }
  }

  @visibleForTesting
  void resetCache() => _cached = null;
}
