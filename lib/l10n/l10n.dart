import 'package:flutter/widgets.dart';

import 'app_language.dart';
import 'app_localizations.dart';

export 'app_language.dart';
export 'app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  /// Строки приложения на выбранном языке.
  ///
  /// Если над виджетом нет делегата локализаций (тест с голым MaterialApp,
  /// оверлей вне приложения), берём тот же язык из [AppLanguageStore], а не
  /// падаем.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ?? currentL10n;
}

/// Строки для кода без BuildContext: сетевые ошибки, локальные уведомления,
/// сервисы.
AppLocalizations get currentL10n =>
    lookupAppLocalizations(AppLanguageStore.current.locale);
