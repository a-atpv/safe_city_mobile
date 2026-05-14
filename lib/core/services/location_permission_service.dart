import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';

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
          const SnackBar(
            content: Text('Службы геолокации отключены. Включите GPS в настройках устройства.'),
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
            content: const Text('Доступ к геолокации запрещён. Откройте настройки приложения.'),
            action: SnackBarAction(
              label: 'Настройки',
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
          const SnackBar(
            content: Text('Службы геолокации отключены. Включите GPS в настройках устройства.'),
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
        title: const Text(
          'Разрешение на геолокацию',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Safe City собирает данные о местоположении для работы функции экстренного вызова SOS, даже когда приложение закрыто или не используется. Эти данные необходимы для оперативного прибытия службы охраны по вашим координатам.',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отклонить', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Принять', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text(
          'Фоновый режим SOS',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Для надежной отправки сигнала SOS при свернутом или закрытом приложении, пожалуйста, выберите «Разрешить в любом режиме» (Allow all the time) в настройках разрешений.',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Позже', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('В настройки', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Настройки потока геолокации (платформо-зависимые)
  // ─────────────────────────────────────────────────────────────────────────

  static LocationSettings getLocationSettings() {
    if (kIsWeb) {
      return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
    }
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        forceLocationManager: true,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Safe City SOS',
          notificationText: 'Отправка координат охране в фоновом режиме',
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.other,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
  }
}
