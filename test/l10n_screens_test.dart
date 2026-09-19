import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_city/core/theme/app_theme.dart';
import 'package:safe_city/features/auth/presentation/login_screen.dart';
import 'package:safe_city/features/auth/presentation/otp_screen.dart';
import 'package:safe_city/features/subscription/data/payment_models.dart';
import 'package:safe_city/features/subscription/presentation/paywall_screen.dart';
import 'package:safe_city/l10n/l10n.dart';
import 'package:safe_city/shared/providers/language_provider.dart';
import 'package:safe_city/shared/providers/payment_provider.dart';
import 'package:safe_city/shared/widgets/language_picker.dart';
import 'package:safe_city/shared/widgets/route_error_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Язык интерфейса: переключение с экрана входа и вёрстка на всех трёх
/// языках.
///
/// Казахские строки заметно длиннее русских, а экраны верстались под русский
/// — поэтому каждый язык прогоняется на самом узком телефоне, какой ещё
/// встречается (iPhone SE первого поколения, 320 точек). Переполнение
/// Flutter сообщает как ошибку, и тест на ней падает.

/// Тарифы без сети — как в paywall_consent_test.
class _FakePaymentNotifier extends PaymentNotifier {
  @override
  PaymentState build() => const PaymentState(plans: [
        Plan(
          code: 'monthly',
          title: 'Месячная',
          amount: 80000,
          currency: 'KZT',
          periodMonths: 1,
        ),
        Plan(
          code: 'yearly',
          title: 'Годовая',
          amount: 690000,
          currency: 'KZT',
          periodMonths: 12,
        ),
      ]);

  @override
  Future<void> fetchPlans() async {}
}

/// MaterialApp с той же настройкой языка, что в main.dart.
class _App extends ConsumerWidget {
  const _App({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      locale: ref.watch(appLanguageProvider).locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );
  }
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        paymentProvider.overrideWith(_FakePaymentNotifier.new),
      ],
      child: _App(home: home),
    ),
  );
  // Не pumpAndSettle: у экрана кода тикает таймер повторной отправки.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Roboto из кэша SDK под своим именем. Без него текст в тестах рисуется
/// шрифтом, где каждая буква шириной в кегль, и «переполнение» ловится там,
/// где на телефоне всё влезает.
Future<void> _loadRealFont() async {
  final dir = '${Platform.environment['FLUTTER_ROOT']}'
      '/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final face in ['Regular', 'Medium', 'Bold', 'Light']) {
    final file = File('$dir/Roboto-$face.ttf');
    if (!file.existsSync()) continue;
    loader.addFont(
      file.readAsBytes().then((bytes) => ByteData.view(bytes.buffer)),
    );
  }
  await loader.load();
}

void main() {
  setUpAll(_loadRealFont);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLanguageStore.load();
  });

  testWidgets('по умолчанию русский, даже если язык телефона другой',
      (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await _pump(tester, const LoginScreen());

    expect(find.text('Получить код'), findsOneWidget);
    expect(find.text('РУС'), findsOneWidget);
  });

  testWidgets('язык меняется с экрана входа и запоминается', (tester) async {
    await _pump(tester, const LoginScreen());

    await tester.tap(find.byType(LanguageButton));
    await tester.pumpAndSettle();
    // Каждый язык подписан на самом себе.
    expect(find.text('Қазақша'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('Қазақша'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Код алу'), findsOneWidget);
    expect(find.text('ҚАЗ'), findsOneWidget);
    // Фраза про документы собрана целиком, глагол — в конце, по-казахски.
    expect(
      find.textContaining('құпиялылық саясатын қабылдайсыз', findRichText: true),
      findsOneWidget,
    );
    expect(AppLanguageStore.current, AppLanguage.kk);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_language'), 'kk');
  });

  testWidgets('выбранный язык переживает перезапуск', (tester) async {
    SharedPreferences.setMockInitialValues({'app_language': 'en'});
    await AppLanguageStore.load();

    await _pump(tester, const LoginScreen());

    expect(find.text('Get code'), findsOneWidget);
    expect(find.text('ENG'), findsOneWidget);
  });

  testWidgets('ошибки проверки формы на выбранном языке', (tester) async {
    await AppLanguageStore.save(AppLanguage.en);
    await _pump(tester, const LoginScreen());

    await tester.tap(find.text('Get code'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
  });

  for (final language in AppLanguage.values) {
    testWidgets('узкий экран без переполнений: ${language.code}',
        (tester) async {
      tester.view.physicalSize = const Size(640, 1136); // 320×568 @2x
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await AppLanguageStore.save(language);

      final screens = <String, Widget>{
        'вход': const LoginScreen(),
        'код из почты': const OtpScreen(email: 'user.name@example.com'),
        'оплата': const PaywallScreen(),
        'нет страницы': const RouteErrorScreen(),
      };

      for (final entry in screens.entries) {
        await _pump(tester, entry.value);
        expect(tester.takeException(), isNull, reason: entry.key);
      }

      // Шторка выбора языка — поверх экрана входа.
      await _pump(tester, const LoginScreen());
      await tester.tap(find.byType(LanguageButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'шторка языка');

      // Гасим таймеры экрана кода.
      await tester.pumpWidget(const SizedBox());
    });
  }
}
