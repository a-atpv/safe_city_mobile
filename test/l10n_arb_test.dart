import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Строки приложения на трёх языках (lib/l10n/app_*.arb).
///
/// gen-l10n молча подставляет русский вместо пропущенного перевода, поэтому
/// забытая строка не ломает сборку, а просто всплывает по-русски посреди
/// казахского экрана. Ловим это здесь: набор ключей и подстановок у всех
/// трёх файлов должен совпадать.
void main() {
  Map<String, String> messages(String locale) {
    final raw = jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;
    return {
      for (final e in raw.entries)
        if (!e.key.startsWith('@')) e.key: e.value as String,
    };
  }

  // {name} и {name, plural, …}; тела веток плюрала ({минута}) не ловим.
  final placeholder =
      RegExp(r'(?<![A-Za-z0-9=])\{([A-Za-z_][A-Za-z0-9_]*)\s*[,}]');
  Set<String> placeholders(String text) =>
      placeholder.allMatches(text).map((m) => m.group(1)!).toSet();

  final ru = messages('ru');

  for (final locale in ['kk', 'en']) {
    group('app_$locale.arb', () {
      final other = messages(locale);

      test('те же ключи, что в русском', () {
        expect(
          other.keys.toSet().difference(ru.keys.toSet()),
          isEmpty,
          reason: 'лишние ключи — в app_ru.arb их нет',
        );
        expect(
          ru.keys.toSet().difference(other.keys.toSet()),
          isEmpty,
          reason: 'не переведено',
        );
      });

      test('те же подстановки и ни одной пустой строки', () {
        for (final key in ru.keys) {
          final text = other[key];
          if (text == null) continue; // отчитался тест выше
          expect(text.trim(), isNotEmpty, reason: key);
          expect(
            placeholders(text),
            placeholders(ru[key]!),
            reason: '$key: подстановки должны совпадать с русской строкой',
          );
        }
      });
    });
  }

  test('в английском нет кириллицы', () {
    final cyrillic = RegExp('[А-Яа-яЁёӘәҒғҚқҢңӨөҰұҮүҺһІі]');
    final leaks = {
      for (final e in messages('en').entries)
        if (cyrillic.hasMatch(e.value)) e.key: e.value,
    };
    expect(leaks, isEmpty);
  });
}
