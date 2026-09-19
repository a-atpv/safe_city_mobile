import 'package:flutter_test/flutter_test.dart';
import 'package:safe_city/core/router/app_router.dart';

/// Оплата уходит во внешний браузер, и единственная дорога назад — ссылка
/// `safecity://pay/...`. Её отдают сразу два источника: app_links и сам движок
/// Flutter, который кладёт её роутеру как обычный адрес. Пока разбора схемы не
/// было, второй источник выводил человеку после списания «Page Not Found:
/// GoException: no routes for location: safecity://pay/success?inv_id=374».
void main() {
  group('payReturnRoute', () {
    test('успешная оплата ведёт на экран подтверждения', () {
      expect(
        payReturnRoute(Uri.parse('safecity://pay/success?inv_id=374')),
        '/subscribe/status',
      );
    });

    test('без параметров — тот же экран', () {
      expect(
        payReturnRoute(Uri.parse('safecity://pay/success')),
        '/subscribe/status',
      );
    });

    test('неудачная оплата возвращает на пейвол', () {
      expect(
        payReturnRoute(Uri.parse('safecity://pay/fail?inv_id=374')),
        '/subscribe',
      );
    });

    test('чужая схема остаётся роутеру', () {
      expect(payReturnRoute(Uri.parse('https://safe-city.kz/success')), isNull);
    });

    test('чужой хост в нашей схеме остаётся роутеру', () {
      expect(payReturnRoute(Uri.parse('safecity://call/success')), isNull);
    });

    test('обычный внутренний адрес не трогаем', () {
      expect(payReturnRoute(Uri.parse('/subscribe/status')), isNull);
    });
  });
}
