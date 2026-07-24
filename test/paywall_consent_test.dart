// The consent gate on the paywall is a payment-system requirement (Robokassa):
// no charge may start without an explicit consent to recurring debits, to
// personal-data processing, and to the public оферта. These tests exist so the
// gate can't be removed by accident.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_city/features/subscription/data/payment_models.dart';
import 'package:safe_city/features/subscription/presentation/paywall_screen.dart';
import 'package:safe_city/shared/providers/payment_provider.dart';

/// Serves the plans catalog offline, so the screen never touches the network.
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

bool _payEnabled(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed !=
    null;

Future<void> _pumpPaywall(WidgetTester tester) async {
  tester.view.physicalSize = const Size(750, 1334); // iPhone SE @2x
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [paymentProvider.overrideWith(_FakePaymentNotifier.new)],
      child: const MaterialApp(home: PaywallScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // url_launcher has no platform implementation under `flutter test`; the
  // recorded calls are the proof that a link span was what got tapped.
  final launchCalls = <String>[];

  setUp(() {
    launchCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async {
        launchCalls.add('${(call.arguments as Map)['url']}');
        return true;
      },
    );
  });

  testWidgets('pay button stays locked until consent is ticked',
      (tester) async {
    await _pumpPaywall(tester);

    // A plan is preselected, so consent is the only thing holding the button.
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(_payEnabled(tester), isFalse);

    // Tapping the block's text (not a link) ticks the box.
    await tester
        .tap(find.textContaining('и принимаю условия', findRichText: true));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(_payEnabled(tester), isTrue);

    // ...and the box toggles consent back off.
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(_payEnabled(tester), isFalse);
  });

  testWidgets('consent links open the docs instead of toggling consent',
      (tester) async {
    await _pumpPaywall(tester);

    await tester.tapOnText(find.textRange.ofSubstring('публичной оферты'));
    await tester.pumpAndSettle();
    expect(launchCalls.single, contains('/legal/public-offer'));

    await tester.tapOnText(
        find.textRange.ofSubstring('обработку персональных данных'));
    await tester.pumpAndSettle();
    expect(launchCalls.last, contains('/legal/privacy-policy'));

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(_payEnabled(tester), isFalse);
  });
}
