import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Языки приложения, в порядке строк шторки выбора.
enum AppLanguage {
  kk('kk', 'Қазақша', 'ҚАЗ'),
  ru('ru', 'Русский', 'РУС'),
  en('en', 'English', 'ENG');

  const AppLanguage(this.code, this.nativeName, this.shortName);

  /// Код для сервера: заголовок `Accept-Language` и поле `language` профиля.
  final String code;

  /// Название на самом языке. В шторке каждый язык подписан по-своему, чтобы
  /// человек нашёл свой, даже не понимая текущего интерфейса.
  final String nativeName;

  /// Подпись на кнопке языка экрана входа.
  final String shortName;

  Locale get locale => Locale(code);

  /// Пока человек сам не выбрал язык — русский, каким бы ни был язык
  /// телефона. Решение владельца от 18.09.2026: казахский и английский
  /// включаются только выбором на экране входа или в профиле.
  static const AppLanguage fallback = AppLanguage.ru;

  static AppLanguage? tryParse(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}

/// Выбранный язык для кода вне дерева виджетов: заголовок запросов, тексты
/// сетевых ошибок, локальные уведомления.
///
/// Читается в `main()` до `runApp`, поэтому первый кадр рисуется уже на
/// выбранном языке, без мигания русским.
class AppLanguageStore {
  AppLanguageStore._();

  static const _prefsKey = 'app_language';

  static AppLanguage _current = AppLanguage.fallback;

  static AppLanguage get current => _current;

  static Future<void> load() async {
    AppLanguage? saved;
    try {
      final prefs = await SharedPreferences.getInstance();
      saved = AppLanguage.tryParse(prefs.getString(_prefsKey));
    } catch (_) {
      // Хранилище недоступно — остаёмся на языке по умолчанию.
    }
    _apply(saved ?? AppLanguage.fallback);
  }

  static Future<void> save(AppLanguage language) async {
    _apply(language);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, language.code);
    } catch (_) {
      // Выбор действует до перезапуска — хуже, чем навсегда, но не ошибка.
    }
  }

  static void _apply(AppLanguage language) {
    _current = language;
    // DateFormat без явной локали берёт её отсюда. Данные дат для kk/ru/en
    // подгружает GlobalMaterialLocalizations до первого экрана.
    Intl.defaultLocale = language.code;
  }
}
