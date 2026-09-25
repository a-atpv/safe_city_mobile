import 'package:flutter_test/flutter_test.dart';
import 'package:safe_city/features/subscription/data/payment_models.dart';
import 'package:safe_city/shared/models/subscription.dart';

/// Покупка уходит в рекламные кабинеты, когда `/user/me` показал, что оплата
/// прошла. Отдельной ручки статуса платежа нет, поэтому решение принимается по
/// подписке — и ошибка в любую сторону стоит денег: пропущенная покупка
/// ослепляет оптимизацию кампаний, ложная — учит их на тех, кто не платил.
void main() {
  final created = DateTime(2026, 9, 25, 12);
  const result = CreatePaymentResult(
    paymentId: 501,
    invId: 9001,
    amount: 169000,
    currency: 'KZT',
    paymentUrl: 'https://auth.robokassa.kz/x',
  );

  Subscription sub({
    int id = 1,
    String status = 'active',
    DateTime? expiresAt,
  }) => Subscription(
    id: id,
    status: status,
    planType: 'monthly',
    expiresAt: expiresAt,
  );

  group('без подписки до оплаты', () {
    final pending = PendingPayment.of(
      'monthly',
      result,
      userId: 7,
      subscriptionBefore: null,
      now: created,
    );

    test('активная подписка — оплата прошла', () {
      expect(
        pending.isConfirmedBy(
          userId: 7,
          subscription: sub(expiresAt: DateTime(2026, 10, 25)),
        ),
        isTrue,
      );
    });

    test('подписка ещё pending — ждём', () {
      expect(
        pending.isConfirmedBy(userId: 7, subscription: sub(status: 'pending')),
        isFalse,
      );
      expect(pending.isConfirmedBy(userId: 7, subscription: null), isFalse);
    });

    test('чужой аккаунт на том же телефоне — не засчитываем', () {
      expect(
        pending.isConfirmedBy(
          userId: 8,
          subscription: sub(expiresAt: DateTime(2026, 10, 25)),
        ),
        isFalse,
      );
    });
  });

  group('продление при уже активной подписке', () {
    final before = sub(id: 3, expiresAt: DateTime(2026, 10, 1));
    final pending = PendingPayment.of(
      'monthly',
      result,
      userId: 7,
      subscriptionBefore: before,
      now: created,
    );

    test('та же подписка с тем же сроком — оплаты ещё не было', () {
      expect(pending.isConfirmedBy(userId: 7, subscription: before), isFalse);
    });

    test('срок сдвинулся — оплата прошла', () {
      expect(
        pending.isConfirmedBy(
          userId: 7,
          subscription: sub(id: 3, expiresAt: DateTime(2026, 11, 1)),
        ),
        isTrue,
      );
    });

    test('новая запись подписки — оплата прошла', () {
      expect(
        pending.isConfirmedBy(
          userId: 7,
          subscription: sub(id: 4, expiresAt: DateTime(2026, 10, 1)),
        ),
        isTrue,
      );
    });
  });

  test('истёкшая подписка до оплаты не мешает засчитать новую', () {
    final pending = PendingPayment.of(
      'monthly',
      result,
      userId: 7,
      subscriptionBefore: sub(id: 3, status: 'expired'),
      now: created,
    );
    expect(
      pending.isConfirmedBy(
        userId: 7,
        subscription: sub(id: 3, expiresAt: DateTime(2026, 10, 25)),
      ),
      isTrue,
    );
  });

  test('переживает запись на диск и обратно', () {
    final pending = PendingPayment.of(
      'yearly',
      result,
      userId: 7,
      subscriptionBefore: sub(id: 3, expiresAt: DateTime(2026, 10, 1)),
      now: created,
    );
    final restored = PendingPayment.fromJson(pending.toJson());
    expect(restored.planCode, 'yearly');
    expect(restored.amount, 169000);
    expect(restored.paymentId, 501);
    expect(restored.userId, 7);
    expect(restored.createdAt, created);
    expect(restored.subscriptionIdBefore, 3);
    expect(restored.expiresAtBefore, DateTime(2026, 10, 1));
  });

  test('платёж старше суток считаем брошенным', () {
    final pending = PendingPayment.of(
      'monthly',
      result,
      userId: 7,
      subscriptionBefore: null,
      now: created,
    );
    expect(pending.isStale(created.add(const Duration(hours: 23))), isFalse);
    expect(pending.isStale(created.add(const Duration(hours: 25))), isTrue);
  });
}
