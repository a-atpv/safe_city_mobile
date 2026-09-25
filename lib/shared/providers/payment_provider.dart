import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics/app_analytics.dart';
import '../../core/api/api.dart';
import '../../features/subscription/data/payment_models.dart';
import 'user_provider.dart';

class PaymentState {
  final List<Plan> plans;
  final bool isLoadingPlans;
  final bool isCreating;
  final bool isCancelling;
  final String? error;

  const PaymentState({
    this.plans = const [],
    this.isLoadingPlans = false,
    this.isCreating = false,
    this.isCancelling = false,
    this.error,
  });

  PaymentState copyWith({
    List<Plan>? plans,
    bool? isLoadingPlans,
    bool? isCreating,
    bool? isCancelling,
    String? error,
  }) {
    return PaymentState(
      plans: plans ?? this.plans,
      isLoadingPlans: isLoadingPlans ?? this.isLoadingPlans,
      isCreating: isCreating ?? this.isCreating,
      isCancelling: isCancelling ?? this.isCancelling,
      error: error,
    );
  }
}

class PaymentNotifier extends Notifier<PaymentState> {
  late final ApiClient _apiClient;

  @override
  PaymentState build() {
    _apiClient = ApiClient();
    return const PaymentState();
  }

  /// Load the subscription plans catalog (source of truth for prices).
  Future<void> fetchPlans() async {
    state = state.copyWith(isLoadingPlans: true, error: null);
    try {
      final response = await _apiClient.dio.get('/payments/plans');
      final list = (response.data['plans'] as List)
          .map((e) => Plan.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(plans: list, isLoadingPlans: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoadingPlans: false,
        error: ApiException.fromDioError(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoadingPlans: false, error: e.toString());
    }
  }

  /// Create a pending payment and return the Robokassa payment URL to open.
  /// Returns null on failure (see [PaymentState.error]).
  Future<CreatePaymentResult?> createPayment(
    String planCode, {
    required bool recurring,
  }) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final response = await _apiClient.dio.post(
        '/payments/create',
        data: {'plan': planCode, 'recurring': recurring},
      );
      final result = CreatePaymentResult.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _rememberPending(planCode, result);
      state = state.copyWith(isCreating: false);
      return result;
    } on DioException catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: ApiException.fromDioError(e).message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(isCreating: false, error: e.toString());
      return null;
    }
  }

  /// Ключ, под которым ждёт подтверждения последний платёж. Один на
  /// устройство: новый платёж вытесняет брошенный старый.
  static const _pendingKey = 'payments.pending_purchase';

  bool _reporting = false;

  Future<void> _rememberPending(
    String planCode,
    CreatePaymentResult result,
  ) async {
    var user = ref.read(userProvider).user;
    if (user == null) {
      await ref.read(userProvider.notifier).fetchUser();
      user = ref.read(userProvider).user;
    }
    if (user == null) return;
    final pending = PendingPayment.of(
      planCode,
      result,
      userId: user.id,
      subscriptionBefore: user.subscription,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingKey, jsonEncode(pending.toJson()));
    } catch (e, st) {
      debugPrint('Pending payment not saved: $e\n$st');
    }
  }

  /// Отправляет событие покупки, если ожидающий платёж подтверждён тем, что
  /// сейчас отдал `/user/me`. Зовётся после каждого успешного `fetchUser` —
  /// на экране статуса оплаты, на главном, в профиле, — поэтому покупка
  /// засчитается, даже если приложение выгрузили, пока человек платил в
  /// браузере, или подтверждение пришло позже двух минут ожидания.
  ///
  /// Одна оплата — одно событие: запись стирается раньше отправки.
  Future<void> reportPurchaseIfConfirmed(User user) async {
    if (_reporting) return;
    _reporting = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingKey);
      if (raw == null) return;

      PendingPayment pending;
      try {
        pending = PendingPayment.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        await prefs.remove(_pendingKey);
        return;
      }

      if (pending.isStale(DateTime.now())) {
        await prefs.remove(_pendingKey);
        return;
      }
      if (!pending.isConfirmedBy(
        userId: user.id,
        subscription: user.subscription,
      )) {
        return;
      }

      await prefs.remove(_pendingKey);
      await AppAnalytics.logPurchase(
        amountTiyn: pending.amount,
        currency: pending.currency,
        plan: pending.planCode,
        orderId: pending.paymentId,
      );
    } catch (e, st) {
      debugPrint('Purchase report failed: $e\n$st');
    } finally {
      _reporting = false;
    }
  }

  /// Turn off auto-renewal. Access is kept until the period ends; only future
  /// recurring charges stop. Returns true on success (see [PaymentState.error]).
  Future<bool> cancelSubscription() async {
    state = state.copyWith(isCancelling: true, error: null);
    try {
      await _apiClient.dio.post('/payments/subscription/cancel');
      state = state.copyWith(isCancelling: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isCancelling: false,
        error: ApiException.fromDioError(e).message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(isCancelling: false, error: e.toString());
      return false;
    }
  }
}

final paymentProvider = NotifierProvider<PaymentNotifier, PaymentState>(
  PaymentNotifier.new,
);
