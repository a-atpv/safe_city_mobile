import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

/// Сообщает, что в сторе появилась новая версия.
///
/// Спрашивает у бэкенда (`GET /app/update`), не устарела ли текущая сборка, и
/// показывает диалог. Два режима, и разница между ними принципиальная:
///
///  * **обновление доступно** — предложение, которое можно закрыть кнопкой
///    «Позже». Показывается при каждом запуске приложения, пока человек не
///    обновится: напоминание раз в сутки слишком легко пропустить;
///  * **обновление обязательно** — сборка несовместима с сервером, диалог не
///    закрывается. Этот режим включается только сменой `APP_USER_MIN_VERSION`
///    на бэкенде и по-настоящему запирает человека, поэтому применять его
///    стоит лишь когда старый клиент действительно не работает.
///
/// Любая ошибка (нет сети, бэкенд молчит) проходит молча: проверка версии —
/// вежливость, а не функция, и мешать запуску она не имеет права.
class UpdatePrompt {
  UpdatePrompt._();

  /// Один раз за запуск: экран может пересоздаваться, диалог — нет.
  static bool _askedThisLaunch = false;

  static Future<void> maybeShow(BuildContext context) async {
    if (_askedThisLaunch) return;
    _askedThisLaunch = true;

    try {
      final info = await PackageInfo.fromPlatform();
      final response = await Dio().get(
        '${AppConstants.apiBaseUrl}/app/update',
        queryParameters: {
          'version': info.version,
          'app': 'user',
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final data = response.data;
      if (data is! Map) return;

      final isRequired = data['update_required'] == true;
      final isAvailable = data['update_available'] == true;
      if (!isRequired && !isAvailable) return;

      if (!context.mounted) return;
      await _show(
        context,
        latestVersion: data['latest_version']?.toString() ?? '',
        storeUrl: data['store_url']?.toString() ?? '',
        message: data['message']?.toString(),
        isRequired: isRequired,
      );
    } catch (_) {
      // Молча: обновление подождёт до следующего запуска.
    }
  }

  static Future<void> _show(
    BuildContext context, {
    required String latestVersion,
    required String storeUrl,
    required bool isRequired,
    String? message,
  }) {
    final text = message?.isNotEmpty == true
        ? message!
        : 'Вышла новая версия приложения.';

    return showDialog<void>(
      context: context,
      barrierDismissible: !isRequired,
      builder: (ctx) => PopScope(
        // Обязательное обновление не обойти системной кнопкой «назад».
        canPop: !isRequired,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.system_update, color: Color(0xFF2563EB), size: 28),
              const SizedBox(width: 8),
              Text(
                isRequired ? 'Нужно обновиться' : 'Вышло обновление',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            latestVersion.isEmpty ? text : '$text\n\nВерсия $latestVersion.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            if (!isRequired)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Позже',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ElevatedButton(
              onPressed: storeUrl.isEmpty
                  ? null
                  : () => launchUrl(
                        Uri.parse(storeUrl),
                        mode: LaunchMode.externalApplication,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Обновить', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
