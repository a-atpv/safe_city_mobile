import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import '../../l10n/l10n.dart';

class LocationPermissionService {
  LocationPermissionService._();

  /// Главная точка входа. Выбирает логику по платформе:
  ///   - iOS: стандартный запрос через geolocator (без Prominent Disclosure — не требуется Apple)
  ///   - Android: двухэтапный запрос с обязательным диалогом раскрытия (требование Google Play)
  ///
  /// Возвращает true, если foreground-доступ к геолокации получен.
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    if (Platform.isIOS || kIsWeb) {
      return _checkAndRequestIOS(context);
    }
    return _checkAndRequestAndroid(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // iOS: простая логика без Prominent Disclosure
  // ─────────────────────────────────────────────────────────────────────────

  static Future<bool> _checkAndRequestIOS(BuildContext context) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.sosLocationServicesOff),
          ),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (context.mounted && permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.permLocationDeniedOpenSettings),
            action: SnackBarAction(
              label: context.l10n.sosSettings,
              onPressed: Geolocator.openAppSettings,
            ),
          ),
        );
      }
      return false;
    }

    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Android: двухэтапный запрос с Prominent Disclosure (требование Google Play)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<bool> _checkAndRequestAndroid(BuildContext context) async {
    // 1. Проверяем, включены ли службы геолокации
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.sosLocationServicesOff),
          ),
        );
      }
      return false;
    }

    // 2. Проверяем Foreground-разрешение
    var whenInUseStatus = await Permission.locationWhenInUse.status;

    if (!whenInUseStatus.isGranted) {
      // Prominent Disclosure ОБЯЗАТЕЛЕН перед системным запросом (Google Play policy)
      if (!context.mounted) return false;
      final accepted = await showProminentDisclosure(context);
      if (accepted != true) return false;

      whenInUseStatus = await Permission.locationWhenInUse.request();
      if (!whenInUseStatus.isGranted) return false;
    }

    // 3. Запрашиваем Background-разрешение (Allow all the time).
    //    В Android 11+ нельзя запросить напрямую — только через настройки.
    final alwaysStatus = await Permission.locationAlways.status;
    if (!alwaysStatus.isGranted && context.mounted) {
      final goToSettings = await _showBackgroundPermissionExplanation(context);
      if (goToSettings == true) {
        await Permission.locationAlways.request();
      }
    }

    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Диалоги (только для Android)
  // ─────────────────────────────────────────────────────────────────────────

  /// Диалог видного раскрытия (Prominent Disclosure) — требование Google Play.
  static Future<bool?> showProminentDisclosure(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          ctx.l10n.permLocationTitle,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          ctx.l10n.permLocationDisclosure,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.permDecline, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(ctx.l10n.permAccept, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Диалог с объяснением необходимости выбора «Разрешить в любом режиме».
  static Future<bool?> _showBackgroundPermissionExplanation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          ctx.l10n.permBackgroundTitle,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          ctx.l10n.permBackgroundBody,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.permLater, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(ctx.l10n.permOpenSettings, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Настройки потока геолокации (платформо-зависимые)
  // ─────────────────────────────────────────────────────────────────────────

  /// Настройки потока на время экстренного вызова.
  ///
  /// `bestForNavigation` + нулевой `distanceFilter`: во время SOS расход батареи
  /// не важен, важно, чтобы точка была максимально точной и не «замирала», когда
  /// человек стоит или его везут медленно. При `distanceFilter: 10` стоящий на
  /// месте человек не давал ни одного нового фикса, и на сервер уходил всё более
  /// старый.
  static LocationSettings getLocationSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        // Просим фикс каждые 2 с — чаще, чем отправка (5 с), чтобы к моменту
        // отправки координата была свежей, а не «доехавшей» с прошлого раза.
        intervalDuration: const Duration(seconds: 2),
        // Используем fused-провайдер (Google Play Services) — он точнее за счёт
        // объединения GPS + Wi-Fi + сети + сенсоров. На устройствах без GMS
        // geolocator сам откатится на LocationManager. Прежнее значение
        // forceLocationManager: true форсировало устаревший LocationManager и
        // давало заметно более грубые координаты.
        forceLocationManager: false,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'Safe City SOS',
          notificationText: currentL10n.locationForegroundNotification,
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        // otherNavigation, а не other: человека могут везти, и iOS не должна
        // считать, что можно снизить частоту фиксов.
        activityType: ActivityType.otherNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Получение и валидация координат
  // ─────────────────────────────────────────────────────────────────────────

  /// Максимальный возраст закэшированного фикса, который считаем пригодным.
  static const Duration _maxCacheAge = Duration(seconds: 30);

  /// Порог точности (в метрах) для стартового фикса. Грубее — не принимаем
  /// кэш и ждём свежий high-accuracy фикс.
  static const double _initialAccuracyThreshold = 50;

  /// Порог точности (в метрах) для непрерывных обновлений во время вызова.
  ///
  /// Клиент этим порогом больше ничего не отбрасывает: решение принимает сервер,
  /// потому что только он знает, есть ли у него точка лучше и не устарела ли она.
  /// Если фильтровать на клиенте, грубый фикс просто не доедет — и оператор
  /// увидит «точка не обновляется» там, где приблизительная точка была бы лучше,
  /// чем никакой. Оставлено для справки и совместимости.
  static const double maxAcceptableAccuracy = 100;

  /// Возвращает максимально точную стартовую координату для создания вызова.
  ///
  /// Кэшированную позицию (getLastKnownPosition) используем только если она
  /// свежая и точная; иначе ждём свежий high-accuracy фикс. Если свежий фикс не
  /// успел прийти за отведённое время, возвращаем кэш как запасной вариант —
  /// для SOS лучше неточная координата, чем полный отказ вызова.
  static Future<Position> getBestInitialPosition() async {
    final cached = await Geolocator.getLastKnownPosition();
    if (cached != null && _isFreshAndAccurate(cached)) {
      return cached;
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
    } on TimeoutException {
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Свежий ли и точный ли фикс (для быстрого пути на старте вызова).
  static bool _isFreshAndAccurate(Position p) {
    final age = DateTime.now().difference(p.timestamp);
    return age <= _maxCacheAge &&
        p.accuracy > 0 &&
        p.accuracy <= _initialAccuracyThreshold;
  }

  /// Подходит ли фикс для отправки во время активного вызова — отсекаем
  /// заведомо грубые сетевые фиксы. Если точность неизвестна (accuracy <= 0),
  /// фикс пропускаем, чтобы не оборвать трекинг.
  static bool isAcceptableFix(Position p) {
    if (p.accuracy <= 0) return true;
    return p.accuracy <= maxAcceptableAccuracy;
  }
}
