import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Готовые адреса бэкенда.
enum BackendPreset {
  prod('Прод', 'safe-city-back-7c8ed50edd7d.herokuapp.com'),
  test('Тест', 'safe-city-back-test-d2f8b35b15f0.herokuapp.com');

  const BackendPreset(this.label, this.host);

  final String label;
  final String host;
}

/// Какой бэкенд слушает приложение.
///
/// По умолчанию — **прод**: сборка в стор не должна зависеть от того, вспомнил
/// ли кто-то передать флаг. Тестовая среда выбирается явно, флагом сборки:
///
///     flutter run --dart-define=SAFECITY_API_HOST=safe-city-back-test-…
///
/// Флаг прибивает хост намертво: CI и ручные тестовые сборки получают заведомо
/// предсказуемый адрес, который из приложения уже не сдвинуть.
///
/// Экрана выбора сервера пока **нет** — [isVisible], [isEditable], [load] и
/// [select] это заготовка под него, и до его появления сохранённый в
/// SharedPreferences адрес читается только в debug. Правило, ради которого всё
/// это устроено так, останется и с экраном: **release без флага использует
/// [_defaultHost]** и сохранённый выбор игнорирует — сборка для App Store не
/// может уехать на чужой адрес из настроек (но уедет туда, куда указывает
/// дефолт, — см. выше). В release меню появится только с
/// `--dart-define=SAFECITY_DEV_MENU=true`, то есть в сборках для внутреннего
/// тестирования.
class BackendEnv {
  BackendEnv._();

  static const String _prefsKey = 'backend_host';

  static const String _pinnedHost = String.fromEnvironment('SAFECITY_API_HOST');
  static const bool _devMenu = bool.fromEnvironment('SAFECITY_DEV_MENU');

  /// Показывать ли раздел выбора сервера в профиле.
  static bool get isVisible => kDebugMode || _devMenu;

  /// Адрес задан флагом сборки — из приложения его не поменять.
  static bool get isPinned => _pinnedHost.isNotEmpty;

  /// Можно ли менять адрес из приложения.
  static bool get isEditable => isVisible && !isPinned;

  /// Адрес по умолчанию — им пользуются и release без dev-меню, и первый
  /// запуск, пока в настройках ничего не выбрано.
  static const BackendPreset _defaultHost = BackendPreset.prod;

  static String _host = _defaultHost.host;

  /// Текущий хост без схемы: `safe-city-back-…herokuapp.com`.
  static String get host => isPinned ? normalizeHost(_pinnedHost) : _host;

  /// Пресет, если адрес совпал с одним из них; иначе null — «свой адрес».
  static BackendPreset? get preset {
    for (final p in BackendPreset.values) {
      if (p.host == host) return p;
    }
    return null;
  }

  static String get label => preset?.label ?? 'Свой адрес';

  /// Локальные адреса (эмулятор, LAN) ходят по http/ws, остальные — по TLS.
  static bool get _isLocal =>
      host.startsWith('localhost') ||
      host.startsWith('127.') ||
      host.startsWith('10.0.2.2') ||
      host.startsWith('192.168.');

  static String get apiBaseUrl =>
      '${_isLocal ? 'http' : 'https'}://$host/api/v1';

  static String get wsBaseUrl => '${_isLocal ? 'ws' : 'wss'}://$host/api/v1';

  /// Читает сохранённый выбор. Вызывать в `main()` ДО первого сетевого вызова:
  /// Dio создаётся лениво и запоминает baseUrl в момент создания.
  static Future<void> load() async {
    if (!isEditable) return; // прибито флагом либо release без dev-меню
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.isNotEmpty) _host = saved;
  }

  /// Сохраняет новый адрес и возвращает его нормализованный вид.
  static Future<String> select(String rawHost) async {
    final next = normalizeHost(rawHost);
    if (!isEditable || next.isEmpty) return host;
    _host = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, next);
    return next;
  }

  /// Приводит что угодно (`https://foo.com/api/v1/`, `foo.com`) к голому хосту.
  static String normalizeHost(String raw) {
    var value = raw.trim().replaceAll(RegExp(r'\s'), '');
    value = value.replaceFirst(RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://'), '');
    return value.split('/').first;
  }
}
