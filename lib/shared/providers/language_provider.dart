import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api.dart';
import '../../l10n/app_language.dart';
import 'auth_provider.dart';

/// Язык интерфейса. Меняется с экрана входа и из профиля, живёт на телефоне
/// ([AppLanguageStore]) и сообщается серверу — чтобы пуши о вызове приходили
/// на нём же, даже когда приложение закрыто.
final appLanguageProvider =
    NotifierProvider<AppLanguageNotifier, AppLanguage>(AppLanguageNotifier.new);

class AppLanguageNotifier extends Notifier<AppLanguage> {
  /// Что сервер уже знает в этой сессии — чтобы не слать одно и то же.
  String? _syncedCode;

  @override
  AppLanguage build() {
    // Язык выбирают и до входа, а в профиле на сервере мог остаться язык с
    // прежнего телефона. Источник правды — телефон: сообщаем язык при каждом
    // входе и восстановлении сессии.
    ref.listen<AuthStatus>(
      authProvider.select((s) => s.status),
      (previous, next) {
        if (next == AuthStatus.authenticated &&
            previous != AuthStatus.authenticated) {
          _syncedCode = null;
          _sendToServer();
        }
      },
    );
    return AppLanguageStore.current;
  }

  Future<void> select(AppLanguage language) async {
    if (language == state) return;
    state = language;
    await AppLanguageStore.save(language);
    if (ref.read(authProvider).status == AuthStatus.authenticated) {
      await _sendToServer();
    }
  }

  Future<void> _sendToServer() async {
    final code = state.code;
    if (_syncedCode == code) return;
    try {
      await ApiClient().dio.patch('/user/settings', data: {'language': code});
      _syncedCode = code;
    } catch (e) {
      // Не страшно: интерфейс уже переключён, а сервер узнает при следующем
      // входе или запуске.
      debugPrint('Language sync failed: $e');
    }
  }
}
