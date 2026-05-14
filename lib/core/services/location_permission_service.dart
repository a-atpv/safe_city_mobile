import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';

class LocationPermissionService {
  LocationPermissionService._();

  /// Выполняет двухэтапный запрос разрешений с Prominent Disclosure, согласно требованиям Google Play.
  /// Возвращает true, если все необходимые разрешения получены (или предоставлен foreground доступ).
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    // 1. Проверяем включены ли службы геолокации
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Службы геолокации отключены. Включите GPS в настройках устройства.')),
        );
      }
      return false;
    }

    // 2. Проверяем текущий статус Permission.locationWhenInUse
    var whenInUseStatus = await Permission.locationWhenInUse.status;

    if (!whenInUseStatus.isGranted) {
      // Показываем Prominent Disclosure ДО системного запроса
      if (!context.mounted) return false;
      bool? accepted = await showProminentDisclosure(context);
      if (accepted != true) {
        return false;
      }

      // После принятия Prominent Disclosure запрашиваем Foreground разрешение
      whenInUseStatus = await Permission.locationWhenInUse.request();
      if (!whenInUseStatus.isGranted) {
        return false;
      }
    }

    // 3. Если мы на Android 11+ (API 30+), проверяем фоновое разрешение (locationAlways)
    if (Platform.isAndroid) {
      var alwaysStatus = await Permission.locationAlways.status;
      if (!alwaysStatus.isGranted) {
        if (!context.mounted) return true; // Мы имеем хотя бы Foreground
        bool? goToSettings = await _showBackgroundPermissionExplanation(context);
        if (goToSettings == true) {
          // Запрашиваем locationAlways. В Android 11+ это перенаправит пользователя в настройки
          alwaysStatus = await Permission.locationAlways.request();
        }
      }
    }

    return true;
  }

  /// Диалог видного раскрытия (Prominent Disclosure)
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

  /// Диалог с объяснением необходимости выбора "Разрешить в любом режиме" (Allow all the time)
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
          'Для надежной отправки сигнала SOS и передачи координат охране при свернутом или закрытом приложении, пожалуйста, выберите «Разрешить в любом режиме» (Allow all the time) в настройках разрешений.',
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

  /// Настройки для фоновой работы геолокации
  static LocationSettings getLocationSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
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
        activityType: ActivityType.emergencyCall,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }
  }
}
